  begin
    csv = CSV.open('preprod_test_data_for_ivlr_1.csv',"r",:headers =>true)
    @data= csv.to_a
    @data_hash = {}
    @data.each do |d|
      if @data_hash[d["family_id"]].present?
        hbx_ids = @data_hash[d["family_id"]].collect{|r| r['glue_hbx_id']}
        next if hbx_ids.include?(d["glue_hbx_id"])
        @data_hash[d["family_id"]] << d
      else
        @data_hash[d["family_id"]] = [d]
      end
    end
  rescue Exception => e
    puts "Unable to open file #{e}"
  end
  field_names  = %w(
          family_id
          hbx_id
        )
  file_name = "#{Rails.root}/public/ivl_renewal_notice_1b_report.csv"

  CSV.open(file_name, "w", force_quotes: true) do |csv|
    csv << field_names

    event_kind = ApplicationEventKind.where(:event_name => 'ivl_renewal_notice_1_second_batch').first
    notice_trigger = event_kind.notice_triggers.first
    @data_hash.each do |family_id , members|
      primary_member = members[0]
      person = Person.where(:hbx_id => primary_member["glue_hbx_id"]).first
      consumer_role =person.consumer_role
      if  consumer_role.present?
        begin
          builder = notice_trigger.notice_builder.camelize.constantize.new(consumer_role, {
                template: notice_trigger.notice_template,
                subject: event_kind.title,
                mpi_indicator: notice_trigger.mpi_indicator,
                data: members
                }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)
                )
          builder.deliver
        rescue Exception => e
          puts "Unable to deliver to #{person.hbx_id} for the following error #{e}"
        end
        csv << [
          family_id,
          person.hbx_id
        ]
      else
        puts "Unable to send notice to family_id : #{family_id}"
      end
    end
  end
