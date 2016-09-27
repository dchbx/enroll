  begin
    csv = CSV.open('ivlr_2_test_data_local.csv',"r",:headers =>true)
    @data= csv.to_a
    @data_hash = {}
    @data.each do |d|
      if @data_hash[d["ic_ref"]].present?
        hbx_ids = @data_hash[d["ic_ref"]].collect{|r| r['personid']}
        next if hbx_ids.include?(d["personid"])
        @data_hash[d["ic_ref"]] << d
      else
        @data_hash[d["ic_ref"]] = [d]
      end
   end
  rescue Exception => e
    puts "Unable to open file #{e}"
  end
  field_names  = %w(
          ic_ref
        )
  file_name = "#{Rails.root}/public/ivl_renewal_notice_2_report.csv"

  CSV.open(file_name, "w", force_quotes: true) do |csv|
    csv << field_names

    event_kind = ApplicationEventKind.where(:event_name => 'ivl_renewal_notice_2').first
    notice_trigger = event_kind.notice_triggers.first
    @data_hash.each do |ic_ref, members|
      primary_member = members[0]
      family = Family.where(:e_case_id => Regexp.new(primary_member["ic_ref"],true)).first
      consumer_role =family.primary_family_member.person.consumer_role
      if consumer_role.present?
        begin
          builder = notice_trigger.notice_builder.camelize.constantize.new(consumer_role, {
                template: notice_trigger.notice_template,
                subject: event_kind.title,
                mpi_indicator: notice_trigger.mpi_indicator,
                data: members,
                primary_identifier: ic_ref
                }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)
                )
          builder.deliver
        rescue Exception => e
          puts "Unable to deliver to #{primary_member["ic_ref"]} for the following error #{e.backtrace}"
        end
        csv << [
          ic_ref
        ]
      else
        puts "Unable to send notice to family_id : #{ic_ref}"
      end
    end
  end
