puts "-------------------------------------- Start of rake: #{TimeKeeper.datetime_of_record} --------------------------------------" unless Rails.env.test?
begin
  @data_hash = {}

  csv_path = if Rails.env.production?
               "proj_elig_report_aqhp_2019.csv"
             else
               "#{Rails.root}/spec/test_data/notices/proj_elig_report_aqhp_2019_test_data.csv"
             end

  CSV.foreach(csv_path, :headers => true).each do |d|
    if @data_hash[d["ic_number"]].present?
      hbx_ids = @data_hash[d["ic_number"]].collect{|r| r['member_id']}
      next if hbx_ids.include?(d["member_id"])
      @data_hash[d["ic_number"]] << d
    else
      @data_hash[d["ic_number"]] = [d]
    end
  end
rescue StandardError => error
  puts "Unable to open file #{error}" unless Rails.env.test?
end

field_names = %w[
        ic_number
        hbx_id
        full_name
      ]

file_name = if Rails.env.production?
              Rails.root.join("projected_eligibility_notice_aqhp_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv")
            else
              "#{Rails.root}/spec/test_data/notices/projected_eligibility_notice_aqhp_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"
            end

CSV.open(file_name, "w", force_quotes: true) do |csv|
  csv << field_names
  @data_hash.each do |ic_number, members|
    begin
      primary_member = members.detect{ |m| m["dependent"].casecmp('NO').zero?}
      dependents = members.select{|m| m["dependent"].casecmp('YES').zero?}
      next if primary_member.nil?
      person = Person.where(:hbx_id => primary_member["subscriber_id"]).first
      primary_person = person.primary_family ? person : person.families.first.primary_applicant.person
      consumer_role = primary_person.consumer_role
      if primary_person.present? && consumer_role.present?
        @notifier = Services::NoticeService.new
        @notifier.deliver(
          recipient: consumer_role,
          event_object: consumer_role,
          notice_event: 'projected_eligibility_notice_2',
          notice_params: {
            dependents: dependents.map(&:to_hash),
            primary_member: primary_member.to_hash
          }
        )
        puts "***************** Notice delivered to #{primary_person.hbx_id} *****************" unless Rails.env.test?
        csv << [
          ic_number,
          primary_person.hbx_id,
          primary_person.full_name
        ]
      else
        puts "No consumer role for #{primary_person.hbx_id} -- #{e}" unless Rails.env.test?
      end
    rescue StandardError => e
      puts "Unable to deliver to projected_eligibility_notice_2 to #{ic_number} - ic number due to the following error #{e.backtrace}" unless Rails.env.test?
    end
  end
  puts "End of IVL_PRE AQHP notice generation" unless Rails.env.test?
end
puts "-------------------------------------- End of rake: #{TimeKeeper.datetime_of_record} --------------------------------------" unless Rails.env.test?
