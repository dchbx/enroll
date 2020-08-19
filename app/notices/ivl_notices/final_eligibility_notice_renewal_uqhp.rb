class IvlNotices::FinalEligibilityNoticeRenewalUqhp < IvlNotice
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
    attach_required_documents if notice.documents_needed
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
    check_for_unverified_individuals
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

    hbx_enrollments << health_enrollments
    hbx_enrollments << dental_enrollments

    return nil if hbx_enrollments.flatten.compact.empty?
    hbx_enrollments.flatten.compact.each do |enrollment|
      notice.enrollments << append_enrollment_information(enrollment)
    end

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
                                     responsible_amount: (enrollment.total_premium - enrollment.applied_aptc_amount.to_f).round(2),
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

  def check_for_unverified_individuals
    family = recipient.primary_family
    enrollments = family.households.flat_map(&:hbx_enrollments).select do |hbx_en|
      (!hbx_en.is_shop?) && (!["coverage_canceled", "shopping", "inactive"].include?(hbx_en.aasm_state)) &&
          (
          hbx_en.terminated_on.blank? ||
              hbx_en.terminated_on >= TimeKeeper.date_of_record
          )
    end
    enrollments.reject!{|e| e.coverage_terminated? }
    family_members = enrollments.inject([]) do |family_members, enrollment|
      family_members += enrollment.hbx_enrollment_members.map(&:family_member)
    end.uniq

    people = family_members.map(&:person).uniq

    outstanding_people = []
    people.each do |person|
      if person.consumer_role.outstanding_verification_types.present?
        outstanding_people << person
      end
    end
    #enrollments.each {|e| e.update_attributes(special_verification_period: TimeKeeper.date_of_record + 95.days)}
    # family.update_attributes(min_verification_due_date: family.min_verification_due_date_on_family)

    # enrollments.select{ |en| HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES.include?(en.aasm_state)}.each do |enrollment|
    #   notice.enrollments << append_enrollment_information(enrollment)
    # end
    notice.due_date = family.min_verification_due_date
    outstanding_people.uniq!
    notice.documents_needed = outstanding_people.present? ? true : false
    append_unverified_individuals(outstanding_people)
  end

  # def document_due_date(family)
  #   enrolled_contingent_enrollment = family.enrollments.where(:aasm_state => "enrolled_contingent", :kind => 'individual').first
  #   if enrolled_contingent_enrollment.present?
  #     if enrolled_contingent_enrollment.special_verification_period.present?
  #       enrolled_contingent_enrollment.special_verification_period
  #     else
  #       (TimeKeeper.date_of_record+95.days)
  #     end
  #   else
  #     nil
  #   end
  # end

  def outstanding_verification_types(person)
    person.consumer_role.outstanding_verification_types.map(&:type_name)
  end

  def ssn_outstanding?(person)
    outstanding_verification_types(person).include?("Social Security Number")
  end

  def lawful_presence_outstanding?(person)
    outstanding_verification_types(person).include?('Citizenship')
  end

  def immigration_status_outstanding?(person)
   outstanding_verification_types(person).include?('Immigration status')
  end

  def american_indian_status_outstanding?(person)
    outstanding_verification_types(person).include?('American Indian Status')
  end

  def residency_outstanding?(person)
    outstanding_verification_types(person).include?('DC Residency')
  end

  def append_unverified_individuals(people)
    people.each do |person|
      if ssn_outstanding?(person)
        notice.ssa_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: notice.due_date, age: person.age_on(TimeKeeper.date_of_record) })
      end

      if lawful_presence_outstanding?(person)
        notice.dhs_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: notice.due_date, age: person.age_on(TimeKeeper.date_of_record) })
      end

      if immigration_status_outstanding?(person)
        notice.immigration_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: notice.due_date, age: person.age_on(TimeKeeper.date_of_record) })
      end

      if american_indian_status_outstanding?(person)
        notice.american_indian_unverified  << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: notice.due_date, age: person.age_on(TimeKeeper.date_of_record) })
      end

      if residency_outstanding?(person)
        notice.residency_inconsistency  << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: notice.due_date, age: person.age_on(TimeKeeper.date_of_record) })
      end
    end
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