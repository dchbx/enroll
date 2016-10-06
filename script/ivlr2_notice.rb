
  unless ARGV[0].present? && ARGV[1].present?
    puts "Please include mandatory params: File name and Event name. Example: rails runner script/ivlr2_notice.rb <file_name> <event_name>"
    puts "Event Names: ivl_renewal_notice_2, ivl_renewal_notice_3, ivl_renewal_notice_4"
    exit
  end

  begin
    NOTICE_GENERATOR = ARGV[1]
    file_name = ARGV[0]
    csv = CSV.open(file_name,"r",:headers =>true)
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
          hbx_id
        )
  file_name = "#{Rails.root}/public/ivl_renewal_notice_2_report.csv"

  CSV.open(file_name, "w", force_quotes: true) do |csv|
    csv << field_names

    case NOTICE_GENERATOR
    when 'ivl_renewal_notice_2'
      event_kind = ApplicationEventKind.where(:event_name => 'ivl_renewal_notice_2').first
    when 'ivl_renewal_notice_3'
      event_kind = ApplicationEventKind.where(:event_name => 'ivl_renewal_notice_3').first
    when 'ivl_renewal_notice_4'
      event_kind = ApplicationEventKind.where(:event_name => 'ivl_renewal_notice_4').first
    end

    notice_trigger = event_kind.notice_triggers.first
    @data_hash.each do |ic_ref, members|
      begin
        primary_member = members.detect{|m| m["subscriber"] == "Y"}
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
            builder = notice_trigger.notice_builder.camelize.constantize.new(consumer_role, {
                  template: notice_trigger.notice_template,
                  subject: event_kind.title,
                  mpi_indicator: notice_trigger.mpi_indicator,
                  data: members,
                  person: person,
                  address: address,
                  primary_identifier: ic_ref
                  }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)
                  )
            builder.deliver
          csv << [
              ic_ref,
              person.hbx_id
            ]
        else
          puts "Unable to send notice to family_id : #{ic_ref}"
        end
      rescue Exception => e
        puts "Unable to deliver to #{ic_ref} for the following error #{e.backtrace}"
        next
      end
    end
  end