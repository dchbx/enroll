# rails runner script/final_catastrophic_notice.rb <file_name>
  file_1 = ARGV[0]
  begin
    csv_ea = CSV.open(file_1,"r",:headers =>true)
  rescue Exception => e
    puts "Unable to open file #{e}"
  end
  field_names = %w(
          hbx_id
          full_name
        )
  file_2 = "#{Rails.root}/public/ivl_renewal_notice_1_report.csv"

  event_kind = ApplicationEventKind.where(:event_name => 'final_catastrophic_plan_2016').first
  notice_trigger = event_kind.notice_triggers.first

  CSV.open(file_2, "w", force_quotes: true) do |csv|
    csv << field_names
    csv_ea.each do |row|
      person = Person.where(:hbx_id => row["Subscriber_HBX_ID"]).first
      consumer_role =person.consumer_role
      if consumer_role.present?
        begin
          builder = notice_trigger.notice_builder.camelize.constantize.new(consumer_role, {
                        template: notice_trigger.notice_template,
                        subject: event_kind.title,
                        mpi_indicator: notice_trigger.mpi_indicator
                        }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)
                        )
          builder.deliver
        rescue Exception => e
          puts "Unable to deliver to #{person.hbx_id} for the following error #{e} #{e.backtrace}"
        end
        csv << [
          person.hbx_id,
          person.full_name
        ]
      else
        puts "No consumer role for #{Subscriber_HBX_ID} #{e.backtrace}"
      end
    end
  end
