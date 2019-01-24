include VerificationHelper

puts "-------------------------------------- Start of rake: #{TimeKeeper.datetime_of_record} --------------------------------------" unless Rails.env.test?
InitialEvents = ["final_eligibility_notice_uqhp", "final_eligibility_notice_renewal_uqhp"]
unless ARGV[0].present? && ARGV[1].present?
  puts "Please include mandatory arguments: File name and Event name. Example: rails runner script/ivl_renewal_notices.rb <file_name> <event_name>" unless Rails.env.test?
  puts "Event Names: ivl_renewal_notice_2, ivl_renewal_notice_3, ivl_renewal_notice_4, final_eligibility_notice_uqhp, final_eligibility_notice_aqhp, final_eligibility_notice_renewal_uqhp, final_eligibility_notice_renewal_aqhp" unless Rails.env.test?
  exit
end

begin
  file_name = ARGV[0]
  event = ARGV[1]
  @data_hash = {}
  CSV.foreach(file_name,:headers =>true).each do |d|
    if @data_hash[d["ic_number"]].present?
      hbx_ids = @data_hash[d["ic_number"]].collect{|r| r['member_id']}
      # next if hbx_ids.include?(d["member_id"])
      @data_hash[d["ic_number"]] << d
    else
      @data_hash[d["ic_number"]] = [d]
    end
  end
rescue Exception => e
  puts "Unable to open file #{e}" unless Rails.env.test?
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


def valid_enrollments(person)
  renewing_hbx_enrollments = []
  active_hbx_enrollments = []
  family = person.primary_family
  enrollments = family.enrollments.where(:aasm_state.in => ["auto_renewing", "coverage_selected", "unverified", "renewing_coverage_selected"], :kind => "individual")
  return [] if enrollments.blank?
  renewing_health_enrollments = enrollments.select{ |e| e.coverage_kind == "health" && e.effective_on.year == 2019}
  renewing_dental_enrollments = enrollments.select{ |e| e.coverage_kind == "dental" && e.effective_on.year == 2019}

  active_health_enrollments = enrollments.select{ |e| e.coverage_kind == "health" && e.effective_on.year == 2018}
  active_dental_enrollments = enrollments.select{ |e| e.coverage_kind == "dental" && e.effective_on.year == 2018}

  active_hbx_enrollments <<  active_health_enrollments
  active_hbx_enrollments << active_dental_enrollments

  active_hbx_enrollments.flatten!.compact!

  renewing_hbx_enrollments << renewing_health_enrollments
  renewing_hbx_enrollments << renewing_dental_enrollments

  renewing_hbx_enrollments.flatten!.compact!
  return renewing_hbx_enrollments, active_hbx_enrollments
end

def get_family(dependents)
  dep_families = dependents.inject({}) do |dep_families, dependent|
    families = get_families_for(dependent)
    dep_families[dependent] = families.map(&:id) if families.present?
  end
  family_ids = dep_families.values.compact.inject(:&)
  (return Family.find(family_ids.first.to_s)) if family_ids.count == 1
end

def get_families_for(dependent)
  person = Person.by_hbx_id(dependent["member_id"]).first
  person.families.to_a if person.present?
end

def get_family_by_policy_id(policy_hbx_id)
  HbxEnrollment.by_hbx_id(policy_hbx_id).first.family.primary_person
end

def get_primary_person(members, subscriber)
  primary_person = get_family_by_policy_id(members.first["policy.id"]) if members.first["policy.id"].present?
  return primary_person if primary_person

  subscriber_person = Person.by_hbx_id(subscriber["subscriber_id"]).first
  primary_person = subscriber_person if (subscriber_person && subscriber_person.primary_family)
  return primary_person if primary_person

  families = Family.where(e_case_id: /#{members.first["ic_number"]}/)
  primary_person = families.first.primary_person if families.count == 1
  return primary_person if primary_person

  family = get_family(members)
  primary_person = family.primary_person if family.present?
  return primary_person if primary_person

  families = subscriber_person.families
  primary_person = families.first.primary_applicant.person if families.count == 1
  return primary_person
end

unless event_kind.present?
  puts "Not a valid event kind. Please check the event name" unless Rails.env.test?
end

#need to exlude this list from UQHP_FEL data set.
# if event == "final_eligibility_notice_uqhp"
#   @excluded_list = []
#   CSV.foreach("final_fel_aqhp_data_set.csv",:headers =>true).each do |d|
#     @excluded_list << d["subscriber_id"]
#   end
# end

CSV.open(report_name, "w", force_quotes: true) do |csv|
  csv << field_names
  @data_hash.each do |ic_number , members|
    begin
      # (next if (members.any?{ |m| @excluded_list.include?(m["member_id"]) })) if event == "final_eligibility_notice_uqhp"
      subscriber = members.detect{ |m| m["dependent"].present? && m["dependent"].upcase == "NO"}
      next if subscriber.nil?
      primary_person = get_primary_person(members, subscriber) if (members.present? && subscriber.present?)
      next if primary_person.nil?
      # next if (subscriber.present? && subscriber["policy.subscriber.person.is_dc_resident?"].upcase == "FALSE") #need to uncomment while running "final_eligibility_notice_renewal_uqhp" notice
      #next if members.select{ |m| m["policy.subscriber.person.is_incarcerated"] == "TRUE"}.present?
      # next if (members.any?{ |m| (m["policy.subscriber.person.citizen_status"] == "non_native_not_lawfully_present_in_us") || (m["policy.subscriber.person.citizen_status"] == "not_lawfully_present_in_us")})  #need to uncomment while running "final_eligibility_notice_renewal_uqhp" notice
      renewing_enrollments, active_enrollments = valid_enrollments(primary_person)
      next if renewing_enrollments.empty?
      consumer_role = primary_person.consumer_role
      if consumer_role.present?
        if InitialEvents.include? event
          family = primary_person.primary_family
          family.set_due_date_on_verification_types
          family.update_attributes(min_verification_due_date: family.min_verification_due_date_on_family)
        end
        builder = notice_trigger.notice_builder.camelize.constantize.new(consumer_role, {
            template: notice_trigger.notice_template,
            subject: event_kind.title,
            event_name: event_kind.event_name,
            mpi_indicator: notice_trigger.mpi_indicator,
            person: primary_person,
            renewing_enrollments: renewing_enrollments,
            active_enrollments: active_enrollments,
            data: members
            }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)
            )
        builder.deliver
        csv << [
          ic_number,
          primary_person.hbx_id,
          primary_person.first_name,
          primary_person.last_name
        ]
        puts "***************** Notice delivered to #{primary_person.hbx_id} *****************" unless Rails.env.test?
      else
        puts "Error for ic_number - #{ic_number} -- #{e}" unless Rails.env.test?
      end
    rescue Exception => e
      puts "Unable to deliver #{event} notice to family - #{ic_number} due to the following error #{e.backtrace}" unless Rails.env.test?
    end
  end
end
puts "-------------------------------------- End of rake: #{TimeKeeper.datetime_of_record} --------------------------------------" unless Rails.env.test?
