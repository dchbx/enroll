  # Refs 11182. Script to generate notices for the remaining batch affected by 10883.
  begin
    
    csv = CSV.open('report_for_11182_1.csv',"r",:headers =>true)
    @data= csv.to_a
    @data_hash = {}
    @data.each do |d|
      if @data_hash[d["family_id"]].present?
        hbx_ids = @data_hash[d["family_id"]].collect{|r| r['hbx_id']}
        next if hbx_ids.include?(d["hbx_id"])
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
  file_name = "#{Rails.root}/ivl_renewal_notice_1_remaining_list_report.csv"

  CSV.open(file_name, "w", force_quotes: true) do |csv|
    csv << field_names

    event_kind = ApplicationEventKind.where(:event_name => 'ivl_renewal_notice_1_remaining_list').first
    notice_trigger = event_kind.notice_triggers.first
    @data_hash.each do |family_id , members|
      primary_member = members[0]
      person = Person.where(:hbx_id => primary_member["hbx_id"]).first
      address = {
          :address_1 => primary_member["glue_address_1"],
          :address_2 => primary_member["glue_address_2"],
          :city => primary_member["glue_city"],
          :state => primary_member["glue_state"],
          :zip => primary_member["glue_zip"]
        }
      consumer_role =person.consumer_role
      if consumer_role.present?
        begin
          builder = notice_trigger.notice_builder.camelize.constantize.new(consumer_role, {
              template: notice_trigger.notice_template,
              subject: event_kind.title,
              mpi_indicator: notice_trigger.mpi_indicator,
              data: members,
              address: address
              }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)
              )
          builder.deliver
        rescue Exception => e
          puts "Unable to deliver to #{person.hbx_id} for the following error #{e} #{e.backtrace}"
        end
        csv << [
          family_id,
          person.hbx_id
        ]
      else
        puts "Unable to send notice to family: #{family_id}"
      end
    end
  end
