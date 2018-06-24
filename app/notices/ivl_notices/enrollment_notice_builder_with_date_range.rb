class IvlNotices::EnrollmentNoticeBuilderWithDateRange < IvlNotice
  include ApplicationHelper

  attr_accessor :hbx_enrollment_hbx_ids

  def initialize(consumer_role, args = {})
    @hbx_enrollment_hbx_ids = args[:options][:hbx_enrollment_hbx_ids]
    args[:recipient] = consumer_role.person.families.first.primary_applicant.person
    args[:notice] = PdfTemplates::ConditionalEligibilityNotice.new
    args[:market_kind] = 'individual'
    args[:recipient_document_store]= consumer_role.person.families.first.primary_applicant.person
    args[:to] = consumer_role.person.families.first.primary_applicant.person.work_email_or_best
    self.header = "notices/shared/header_ivl.html.erb"
    super(args)
  end

  def deliver
    append_hbe
    build
    generate_pdf_notice
    attach_blank_page(notice_path)
    attach_docs
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

  def attach_docs
    attach_required_documents if (notice.documents_needed && !notice.cover_all?)
  end

  def build
    notice.notification_type = self.event_name
    notice.mpi_indicator = self.mpi_indicator
    notice.primary_identifier = recipient.hbx_id
    append_open_enrollment_data
    check_for_unverified_individuals
    notice.primary_fullname = recipient.full_name.titleize || ""
    notice.primary_firstname = recipient.first_name.titleize || ""
    if recipient.mailing_address
      append_address(recipient.mailing_address)
    else
      # @notice.primary_address = nil
      raise 'mailing address not present'
    end
  end



  def append_open_enrollment_data
    hbx = HbxProfile.current_hbx
    bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if (bcp.start_on..bcp.end_on).cover?(TimeKeeper.date_of_record.next_year) }
    notice.ivl_open_enrollment_start_on = bc_period.open_enrollment_start_on
    notice.ivl_open_enrollment_end_on = bc_period.open_enrollment_end_on
  end

  def append_member_information(people)
    people.each do |member|
      notice.individuals << PdfTemplates::Individual.new({
        :first_name => member.first_name.titleize,
        :last_name => member.last_name.titleize,
        :full_name => member.full_name.titleize,
        :age => calculate_age_by_dob(member.dob),
        :residency_verified => member.consumer_role.residency_verified?
        })
    end
  end

  def check_for_unverified_individuals
    family = recipient.primary_family
    date = TimeKeeper.date_of_record

    hbx_enrollments = @hbx_enrollment_hbx_ids.inject([]) do | hbx_enrollments, hbx_id|
      hbx_enrollments << HbxEnrollment.all.by_hbx_id(hbx_id)
    end
    hbx_enrollments.flatten!
    hbx_enrollments.compact!
    hbx_enrollments.uniq!

    family_members = hbx_enrollments.inject([]) do |family_members, enrollment|
      family_members += enrollment.hbx_enrollment_members.map(&:family_member)
    end.uniq

    people = family_members.map(&:person).uniq
    append_member_information(people)

    outstanding_people = []
    people.each do |person|
      if person.consumer_role.outstanding_verification_types.present?
        outstanding_people << person
        update_individual_due_date(person, date)
      end
    end

    family.update_attributes(min_verification_due_date: family.min_verification_due_date_on_family) unless family.min_verification_due_date.present?

    hbx_enrollments.each do |enrollment|
      notice.enrollments << append_enrollment_information(enrollment)
    end

    notice.coverage_year = hbx_enrollments.compact.first.effective_on.year
    notice.due_date = (family.min_verification_due_date.present? && (family.min_verification_due_date > date)) ? family.min_verification_due_date : min_notice_due_date(family)
    outstanding_people.uniq!
    notice.documents_needed = family.has_valid_e_case_id? ? false : (outstanding_people.present? ? true : false)
    append_unverified_individuals(outstanding_people)
  end

  def min_notice_due_date(family)
    due_dates = []
    family.contingent_enrolled_active_family_members.each do |family_member|
      family_member.person.verification_types.each do |v_type|
        due_dates << family.document_due_date(family_member, v_type)
      end
    end
    due_dates.compact!
    earliest_future_due_date = due_dates.select{ |d| d > TimeKeeper.date_of_record }.min
    if due_dates.present? && earliest_future_due_date.present?
      earliest_future_due_date.to_date
    else
      nil
    end
  end

  def update_individual_due_date(person, date)
    person.consumer_role.outstanding_verification_types.each do |verification_type|
      unless person.consumer_role.special_verifications.where(:"verification_type" => verification_type).present?
        special_verification = SpecialVerification.new(due_date: (date + Settings.aca.individual_market.verification_due.days), verification_type: verification_type, type: "notice")
        person.consumer_role.special_verifications << special_verification
        person.consumer_role.save!
      end
    end
  end

  def ssn_outstanding?(person)
    person.consumer_role.outstanding_verification_types.include?("Social Security Number")
  end

  def lawful_presence_outstanding?(person)
    person.consumer_role.outstanding_verification_types.include?('Citizenship')
  end

  def immigration_status_outstanding?(person)
   person.consumer_role.outstanding_verification_types.include?('Immigration status')
  end

  def american_indian_status_outstanding?(person)
    person.consumer_role.outstanding_verification_types.include?('American Indian Status')
  end

  def residency_outstanding?(person)
    person.consumer_role.outstanding_verification_types.include?('DC Residency')
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

  def document_due_date(person, verification_type)
    special_verification = person.consumer_role.special_verifications.where(verification_type: verification_type).sort_by(&:created_at).last
    special_verification.present? ? special_verification.due_date : nil
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
      created_at: enrollment.created_at,
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
end
