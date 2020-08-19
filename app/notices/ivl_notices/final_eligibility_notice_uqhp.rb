class IvlNotices::FinalEligibilityNoticeUqhp < IvlNotice
  include ApplicationHelper
  attr_accessor :family, :data, :person

  def initialize(consumer_role, args = {})
    args[:recipient] = consumer_role.person
    args[:notice] = PdfTemplates::ConditionalEligibilityNotice.new
    args[:market_kind] = 'individual'
    args[:recipient_document_store]= consumer_role.person
    args[:to] = consumer_role.person.work_email_or_best
    self.person = args[:person]
    self.data = args[:data]
    self.header = "notices/shared/header_ivl.html.erb"
    super(args)
  end

  def deliver
    build
    generate_pdf_notice
    attach_blank_page(notice_path)
    attach_appeals
    attach_non_discrimination
    attach_taglines
    upload_and_send_secure_message

    if recipient.consumer_role.can_receive_electronic_communication?
      send_generic_notice_alert
    end

    if recipient.consumer_role.can_receive_paper_communication?
      store_paper_notice
    end
  end

  def build
    append_data
    pick_enrollments
    append_hbe
    if recipient.mailing_address
      append_address(recipient.mailing_address)
    else
      raise 'mailing address not present'
    end
  end

  def pick_enrollments
    hbx_enrollments = []
    family = recipient.primary_family
    enrollments = family.enrollments.where(:aasm_state.in => ["auto_renewing", "coverage_selected", "unverified", "renewing_coverage_selected"], :kind => "individual")
    return nil if enrollments.blank?
    health_enrollments = enrollments.detect{ |e| e.coverage_kind == "health" && e.effective_on.year.to_s == notice.coverage_year}
    dental_enrollments = enrollments.detect{ |e| e.coverage_kind == "dental" && e.effective_on.year.to_s == notice.coverage_year}

    previous_health_enrollments = enrollments.detect{ |e| e.coverage_kind == "health" && e.effective_on.year.to_s == notice.current_year}
    previous_dental_enrollments = enrollments.detect{ |e| e.coverage_kind == "dental" && e.effective_on.year.to_s == notice.current_year}

    renewal_health_plan_id = (previous_health_enrollments.plan.renewal_plan_id) rescue nil
    renewal_health_plan_hios_base_id = (previous_health_enrollments.plan.hios_base_id) rescue nil
    future_health_plan_id = (health_enrollments.plan.id) rescue nil
    future_health_plan_hios_base_id = (health_enrollments.plan.hios_base_id) rescue nil

    renewal_dental_plan_id = (previous_dental_enrollments.plan.renewal_plan_id) rescue nil
    renewal_dental_plan_hios_base_id = (previous_dental_enrollments.plan.hios_base_id) rescue nil
    future_dental_plan_id = (dental_enrollments.plan.id) rescue nil
    future_dental_plan_hios_base_id = (dental_enrollments.plan.hios_base_id) rescue nil

    notice.same_plan_health_enrollment = (renewal_health_plan_id && future_health_plan_id) ? ((renewal_health_plan_id == future_health_plan_id) && (renewal_health_plan_hios_base_id == future_health_plan_hios_base_id )) : false
    notice.same_plan_dental_enrollment = (renewal_dental_plan_id && future_dental_plan_id) ? ((renewal_dental_plan_id == future_dental_plan_id) && (renewal_dental_plan_hios_base_id == future_dental_plan_hios_base_id) ) : false

    hbx_enrollments << health_enrollments
    hbx_enrollments << dental_enrollments
    return nil if hbx_enrollments.flatten.compact.empty?
    notice.health_enrollments << (append_enrollment_information(health_enrollments) if health_enrollments)
    notice.dental_enrollments << (append_enrollment_information(dental_enrollments) if dental_enrollments)
    notice.health_enrollments.flatten!
    notice.health_enrollments.compact!
    notice.dental_enrollments.flatten!
    notice.dental_enrollments.compact!
    notice.enrollments << notice.health_enrollments
    notice.enrollments << notice.dental_enrollments
    notice.enrollments.flatten!
    notice.enrollments.compact!

    family_members = hbx_enrollments.flatten.compact.inject([]) do |family_members, enrollment|
      family_members += enrollment.hbx_enrollment_members.map(&:family_member)
    end.uniq

    family_members.map(&:person).each do |prson|
      append_member_information(prson)
    end
  end

  def append_enrollment_information(enrollment)
    plan = PdfTemplates::Plan.new({
      plan_name: enrollment.plan.name,
      is_csr: enrollment.plan.is_csr?,
      coverage_kind: enrollment.plan.coverage_kind,
      plan_carrier: enrollment.plan.carrier_profile.organization.legal_name,
      family_deductible: enrollment.plan.family_deductible.split("|").last.squish,
      deductible: enrollment.plan.deductible
      })
    PdfTemplates::Enrollment.new({
      premium: enrollment.total_premium.round(2),
      aptc_amount: enrollment.applied_aptc_amount.round(2),
      responsible_amount: number_to_currency((enrollment.total_premium - enrollment.applied_aptc_amount.to_f), precision: 2),
      phone: phone_number(enrollment.plan.carrier_profile.legal_name),
      is_receiving_assistance: (enrollment.applied_aptc_amount > 0 || enrollment.plan.is_csr?) ? true : false,
      coverage_kind: enrollment.coverage_kind,
      kind: enrollment.kind,
      effective_on: enrollment.effective_on,
      plan: plan,
      enrollees: enrollment.hbx_enrollment_members.inject([]) do |enrollees, member|
        enrollee = PdfTemplates::Individual.new({
          full_name: member.person.full_name.titleize,
          age: member.person.age_on(TimeKeeper.date_of_record)
        })
        enrollees << enrollee
      end
    })
  end

  def append_member_information(member)
    notice.individuals << PdfTemplates::Individual.new({
      :first_name => member.first_name.titleize,
      :last_name => member.last_name.titleize,
      :full_name => member.full_name.titleize,
      :age => calculate_age_by_dob(member.dob),
      :incarcerated => member.is_incarcerated? ? "Yes" : "No",
      :citizen_status => citizen_status(member.citizen_status),
      :residency_verified => is_dc_resident(recipient) ? "Yes" : "No",
      :is_without_assistance => true,
      :is_totally_ineligible => is_totally_ineligible(member)
      })
  end

  def append_data
    notice.notification_type = self.event_name
    notice.mpi_indicator = self.mpi_indicator
    notice.primary_identifier = recipient.hbx_id
    notice.coverage_year = TimeKeeper.date_of_record.next_year.year
    notice.current_year = TimeKeeper.date_of_record.year
    notice.ivl_open_enrollment_start_on = Settings.aca.individual_market.open_enrollment.start_on
    notice.ivl_open_enrollment_end_on = Settings.aca.individual_market.open_enrollment.end_on
    notice.primary_fullname = recipient.full_name.titleize || ""
    notice.primary_firstname = recipient.first_name.titleize
  end

  def is_totally_ineligible(person)
    !is_dc_resident(recipient) && person.is_incarcerated? && ConsumerRole::INELIGIBLE_CITIZEN_VERIFICATION.include?(person.citizen_status)
  end

  def is_dc_resident(person)
    return false if person.no_dc_address == true && (person.is_homeless? || person.is_temporarily_out_of_state?)
    return true if person.no_dc_address == true && (person.is_homeless? || person.is_temporarily_out_of_state?)

    address_to_use = person.addresses.collect(&:kind).include?('home') ? 'home' : 'mailing'
    if person.addresses.present?
      if person.addresses.select{|address| address.kind == address_to_use && address.state == 'DC'}.present?
        return true
      else
        return false
      end
    else
      return ""
    end
  end

  def phone_number(legal_name)
    case legal_name
    when "BestLife"
      "(800) 433-0088"
    when "CareFirst"
      "(855) 444-3119"
    when "Delta Dental"
      "(800) 471-0236"
    when "Dominion"
      "(855) 224-3016"
    when "Kaiser"
      "(844) 524-7370"
    end
  end

  def citizen_status(status)
    case status
    when "us_citizen"
      "US Citizen"
    when "LP"
      "Lawfully Present"
    when "NC"
      "US Citizen"
    else
      ""
    end
  end

end