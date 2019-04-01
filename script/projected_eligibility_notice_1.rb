puts "-------------------------------------- Start of rake: #{TimeKeeper.datetime_of_record} --------------------------------------" unless Rails.env.test?
begin
  @data_hash = {}

  csv_path = if Rails.env.production?
               "proj_elig_report_uqhp_2019.csv"
             else
               "#{Rails.root}/spec/test_data/notices/proj_elig_report_uqhp_2019_test_data.csv"
             end

  CSV.foreach(csv_path, :headers => true).each do |d|
    if @data_hash[d["family.id"]].present?
      hbx_ids = @data_hash[d["family.id"]].collect{|r| r['person_hbx_id']}
      next if hbx_ids.include?(d["person_hbx_id"])
      @data_hash[d["family.id"]] << d
    else
      @data_hash[d["family.id"]] = [d]
    end
  end
rescue StandardError => error
  puts "Unable to open file #{error}" unless Rails.env.test?
end

field_names = %w[family.id hbx_id full_name]

file_name = if Rails.env.production?
              Rails.root.join("projected_eligibility_notice_uqhp_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv")
            else
              "#{Rails.root}/spec/test_data/notices/projected_eligibility_notice_uqhp_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"
            end

CSV.open(file_name, "w", force_quotes: true) do |csv|
  csv << field_names
  @data_hash.each do |family_id, members|
    begin
      subscriber = members.detect{ |m| m["dependent"].casecmp('NO').zero? }
      dependents = members.select{|m| m["dependent"].casecmp('YES').zero? }
      primary_person = HbxEnrollment.by_hbx_id(members.first["applid"]).first.family.primary_person
      next if primary_person.nil?
      next if subscriber.present? && subscriber["resident"] && subscriber["resident"].casecmp('NO').zero?
      next if members.select{ |m| m["incarcerated"] && m["incarcerated"].casecmp('YES').zero? }.present?
      next if members.any?{ |m| m["citizen_status"].blank? || (m["citizen_status"] == "non_native_not_lawfully_present_in_us") || (m["citizen_status"] == "not_lawfully_present_in_us")}
      consumer_role = primary_person.consumer_role
      if consumer_role.present?
        begin
          @notifier = Services::NoticeService.new
          @notifier.deliver(
            recipient: consumer_role,
            event_object: consumer_role,
            notice_event: 'projected_eligibility_notice_1',
            notice_params: {
              dependents: dependents.map(&:to_hash),
              primary_member: subscriber.to_hash
            }
          )
          csv << [
            family_id,
            primary_person.hbx_id,
            primary_person.full_name
          ]
          puts "***************** Notice delivered to #{primary_person.hbx_id} *****************" unless Rails.env.test?
        rescue StandardError => e
          puts "Unable to deliver to #{primary_person.hbx_id} due to the following error #{e}" unless Rails.env.test?
        end
      else
        puts "No consumer role for #{primary_person.hbx_id} -- #{e}" unless Rails.env.test?
      end
    rescue StandardError => e
      puts "Unable to process family_id: #{family_id} due to the following error #{e}" unless Rails.env.test?
    end
  end
  puts "End of IVL_PRE UQHP notice generation" unless Rails.env.test?
end
puts "-------------------------------------- End of rake: #{TimeKeeper.datetime_of_record} --------------------------------------" unless Rails.env.test?
