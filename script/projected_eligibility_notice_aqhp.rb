begin
  @data_hash = {}
  CSV.foreach('proj_elig_report_aqhp.csv',:headers =>true).each do |d|
    if @data_hash[d["ic_number"]].present?
      hbx_ids = @data_hash[d["ic_number"]].collect{|r| r['member_id']}
      next if hbx_ids.include?(d["member_id"])
      @data_hash[d["ic_number"]] << d
    else
      @data_hash[d["ic_number"]] = [d]
    end
  end
rescue Exception => e
  puts "Unable to open file #{e}"
end

field_names  = %w(
        ic_number
        hbx_id
        full_name
      )
file_name = "#{Rails.root}/projected_eligibility_notice_aqhp_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"

#open enrollment information
hbx = HbxProfile.current_hbx
bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if bcp.start_on.year.to_s == TimeKeeper.date_of_record.next_year.year.to_s }

CSV.open(file_name, "w", force_quotes: true) do |csv|
  csv << field_names
  event_kind = ApplicationEventKind.where(:event_name => 'projected_eligibility_notice_2').first
  notice_trigger = event_kind.notice_triggers.first
  @data_hash.each do |ic_number , members|
    begin
      primary_member = members.detect{ |m| m["dependent"].upcase == "NO"}
      next if primary_member.nil?
      person = Person.where(:hbx_id => primary_member["subscriber_id"]).first
      consumer_role = person.consumer_role
      if person.present? && consumer_role.present?
        builder = notice_trigger.notice_builder.camelize.constantize.new(consumer_role, {
            template: notice_trigger.notice_template,
            subject: event_kind.title,
            event_name: event_kind.event_name,
            mpi_indicator: notice_trigger.mpi_indicator,
            person: person,
            open_enrollment_start_on: bc_period.open_enrollment_start_on,
            open_enrollment_end_on: bc_period.open_enrollment_end_on,
            data: members
            }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)
            )
        builder.deliver
        csv << [
          ic_number,
          person.hbx_id,
          person.full_name
        ]
      else
        puts "No consumer role for #{person.hbx_id} -- #{e}"
      end
    rescue Exception => e
      puts "Unable to deliver to projected_eligibility_notice_2 to #{ic_number} - ic number due to the following error #{e.backtrace}"
    end

  end
end
