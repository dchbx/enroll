include VerificationHelper

puts "-------------------------------------- Start of rake: #{TimeKeeper.datetime_of_record} --------------------------------------" unless Rails.env.test?

InitialEvents = ['final_eligibility_notice_renewal', 'final_eligibility_notice']

unless ARGV[0].present? && ARGV[1].present? && ARGV[2].present?
  raise "Please include mandatory arguments: File name and Event name. Example: rails runner script/final_eligibility_notice_script.rb <file_name> <event_name> <eligibility_kind> <file_path_to_exclude>"
end

begin
  file_name = ARGV[0]
  event_name = ARGV[1]
  eligibility_kind = ARGV[2]
  excluded_list_file_path = ARGV[3]
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

report_name = if Rails.env.production?
              "#{Rails.root}/#{event_name}_#{eligibility_kind}_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"
            else
              "#{Rails.root}/spec/test_data/notices/#{event_name}_#{eligibility_kind}_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"
            end

def valid_enrollments(person)
  renewing_hbx_enrollments = []
  active_hbx_enrollments = []
  family = person.primary_family
  enrollments = HbxEnrollment.where(family_id: family.id, :aasm_state.in => ["auto_renewing", "coverage_selected", "unverified", "renewing_coverage_selected"], :kind => "individual")
  return [renewing_hbx_enrollments, active_hbx_enrollments] if enrollments.blank?
  renewing_health_enrollments = enrollments.select{ |e| e.coverage_kind == "health" && e.effective_on.year == TimeKeeper.date_of_record.next_year.year}
  renewing_dental_enrollments = enrollments.select{ |e| e.coverage_kind == "dental" && e.effective_on.year == TimeKeeper.date_of_record.next_year.year}

  active_health_enrollments = enrollments.select{ |e| e.coverage_kind == "health" && e.effective_on.year == TimeKeeper.date_of_record.year}
  active_dental_enrollments = enrollments.select{ |e| e.coverage_kind == "dental" && e.effective_on.year == TimeKeeper.date_of_record.year}

  active_hbx_enrollments << active_health_enrollments
  active_hbx_enrollments << active_dental_enrollments

  active_hbx_enrollments.flatten!.compact!

  renewing_hbx_enrollments << renewing_health_enrollments
  renewing_hbx_enrollments << renewing_dental_enrollments

  renewing_hbx_enrollments.flatten!.compact!
  [renewing_hbx_enrollments, active_hbx_enrollments]
end

def get_family(dependents)
  dependent_families = {}
  dep_families = dependents.each do |dependent|
    families = get_families_for(dependent)
    dependent_families[dependent] = families.map(&:id) if families.present?
  end
  family_ids = dependent_families.values.compact.inject(:&)
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
  primary_person = subscriber_person if subscriber_person&.primary_family
  return primary_person if primary_person

  families = Family.where(e_case_id: /#{members.first["ic_number"]}/)
  primary_person = families.first.primary_person if families.count == 1
  return primary_person if primary_person

  family = get_family(members)
  primary_person = family.primary_person if family.present?
  return primary_person if primary_person

  families = subscriber_person.families
  primary_person = families.first.primary_applicant.person if families.count == 1
  primary_person
end

#need to exlude this list from UQHP_FEL data set.
if InitialEvents.include?(event_name) && eligibility_kind.upcase == 'AQHP'
  @excluded_list = []
  raise 'Please provide file path to exclude individuals from notice generation' unless excluded_list_file_path.present?

  CSV.foreach(excluded_list_file_path, :headers => true).each do |d|
    @excluded_list << d["hbx_id"]
  end
end

CSV.open(report_name, "w", force_quotes: true) do |csv|
  csv << field_names
  @data_hash.each do |ic_number , members|
    begin
      next if InitialEvents.include?(event_name) && eligibility_kind.upcase == 'AQHP' && members.any?{ |m| @excluded_list.include?(m["member_id"]) }
      subscriber = members.detect{ |m| m["dependent"].casecmp('NO').zero? }
      dependents = members.select{|m| m["dependent"].casecmp('YES').zero? }
      next if subscriber.nil?

      primary_person = get_primary_person(members, subscriber) if members.present? && subscriber.present?
      next if primary_person.nil?

      #next if (subscriber.present? && subscriber["policy.subscriber.person.is_dc_resident?"].upcase == "FALSE") #need to uncomment while running "final_eligibility_notice_renewal_uqhp" notice
      #next if members.select{ |m| m["policy.subscriber.person.is_incarcerated"] == "TRUE"}.present?
      #next if (members.any?{ |m| (m["policy.subscriber.person.citizen_status"] == "non_native_not_lawfully_present_in_us") || (m["policy.subscriber.person.citizen_status"] == "not_lawfully_present_in_us")})  #need to uncomment while running "final_eligibility_notice_renewal_uqhp" notice
      renewing_enrollments, active_enrollments = valid_enrollments(primary_person)
      next if renewing_enrollments.empty?

      consumer_role = primary_person.consumer_role
      if consumer_role.present?
        if ['final_eligibility_notice_renewal', 'ivl_backlog_verification_notice_uqhp'].include?(event_name)
          family = primary_person.primary_family
          family.set_due_date_on_verification_types
          family.update_attributes!(min_verification_due_date: (family.min_verification_due_date_on_family || (TimeKeeper.date_of_record + 95.days)))
        end
        @notifier = Services::NoticeService.new
        @notifier.deliver(
          recipient: consumer_role,
          event_object: consumer_role,
          notice_event: event_name,
          notice_params: {
            primary_member: subscriber.to_hash,
            dependents: dependents.map(&:to_hash),
            active_enrollment_ids: active_enrollments.pluck(:hbx_id),
            renewing_enrollment_ids: renewing_enrollments.pluck(:hbx_id),
            uqhp_event: eligibility_kind
          }
        )

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
      puts "Unable to deliver #{event_name} notice to family - #{ic_number} due to the following error #{e.backtrace}" unless Rails.env.test?
    end
  end
end
puts "-------------------------------------- End of rake: #{TimeKeeper.datetime_of_record} --------------------------------------" unless Rails.env.test?
