include VerificationHelper

InitialEvents = ["ivl_backlog_verification_notice_uqhp"]
unless ARGV[0].present? && ARGV[1].present?
  puts "Please include mandatory arguments: File name and Event name. Example: rails runner script/ivl_backlog_verification_notice_script.rb <file_name> <event_name>" unless Rails.env.test?
  puts "Event Name: ivl_backlog_verification_notice_uqhp" unless Rails.env.test?
  exit
end

begin
  file_name = ARGV[0]
  event = ARGV[1]
  @data_hash = {}
  CSV.foreach(file_name,:headers =>true).each do |d|
    if @data_hash[d["ic_number"]].present?
      hbx_ids = @data_hash[d["ic_number"]].collect{|r| r['member_id']}
      @data_hash[d["ic_number"]] << d
    else
      @data_hash[d["ic_number"]] = [d]
    end
  end
rescue Exception => e
  puts "Unable to open file #{e}"
end

field_names = %w(
        ic_number
        hbx_id
        first_name
        last_name
      )
report_name = "#{Rails.root}/#{event}_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"

event_kind = ApplicationEventKind.where(:event_name => event).first
notice_trigger = event_kind.notice_triggers.first


def set_due_date_on_verification_types(family)
  family.family_members.each do |family_member|
    begin
      person = family_member.person
      person.verification_types.each do |v_type|
        next if !type_unverified?(v_type, person)
        person.consumer_role.special_verifications << SpecialVerification.new(due_date: future_date,
                                                                              verification_type: v_type,
                                                                              updated_by: nil,
                                                                              type: "notice")
        person.consumer_role.save!
      end
    rescue Exception => e
      puts "Exception in family ID #{primary_person.primary_family.id}: #{e}"
    end
  end
end

def future_date
  TimeKeeper.date_of_record + 95.days
end

unless event_kind.present?
  puts "Not a valid event kind. Please check the event name" unless Rails.env.test?
end

CSV.open(report_name, "w", force_quotes: true) do |csv|
  csv << field_names
  @data_hash.each do |ic_number , members|
    begin
      primary_member = members.detect{ |m| m["dependent"].upcase == "NO"}
      if primary_member.nil?
        family_member =  members.first
        person = Person.where(:hbx_id => family_member["subscriber_id"]).first
      else
        person = Person.where(:hbx_id => primary_member["subscriber_id"]).first
      end
      next if !person.present?
      consumer_role = person.consumer_role
      if consumer_role.present?
        if InitialEvents.include? event
          family = person.primary_family || person.families.first
          set_due_date_on_verification_types(family)
          family.update_attributes(min_verification_due_date: family.min_verification_due_date_on_family)
        end
        builder = notice_trigger.notice_builder.camelize.constantize.new(consumer_role, {
            template: notice_trigger.notice_template,
            subject: event_kind.title,
            event_name: event_kind.event_name,
            mpi_indicator: notice_trigger.mpi_indicator,
            person: person,
            family: family,
            data: members
        }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)
        )
        builder.deliver
        csv << [
            ic_number,
            person.hbx_id,
            person.first_name,
            person.last_name
        ]
      else
        puts "Error for ic_number - #{ic_number} -- #{e}" unless Rails.env.test?
      end
    rescue Exception => e
      puts "Unable to deliver #{event} notice to family - #{ic_number} due to the following error #{e.backtrace}" unless Rails.env.test?
    end

  end
end
