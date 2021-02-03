class IvlNotices::IvlToCoverallTransitionNoticeBuilder < IvlNotice
  include ApplicationHelper

  def initialize(consumer_role, args = {})
    @family = Family.find(args[:options][:family])
    find_transition_people(args[:options][:result][:people])
    args[:recipient] = @family.primary_applicant.person
    args[:notice] = PdfTemplates::ConditionalEligibilityNotice.new
    args[:market_kind] = 'individual'
    args[:recipient_document_store]= @family.primary_applicant.person
    args[:to] = @family.primary_applicant.person.work_email_or_best
    self.header = "notices/shared/header_ivl.html.erb"
    super(args)
  end

  def attach_required_documents
    generate_custom_notice('notices/ivl/documents_section')
    attach_blank_page(custom_notice_path)
    join_pdfs [notice_path, custom_notice_path]
    clear_tmp(custom_notice_path)
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
    clear_tmp(notice_path)
  end

  def attach_docs
    attach_required_documents
  end

  def notice_filename
    "#{subject.titleize.gsub("Dc", "DC").gsub(/[^0-9a-z]/i,'')}"
  end

  def build
    notice.notification_type = self.event_name
    notice.mpi_indicator = self.mpi_indicator
    notice.primary_identifier = recipient.hbx_id
    check_for_transitioned_individuals
    check_for_unverified_individuals
    append_unverified_individuals
    notice.primary_fullname = recipient.full_name.titleize || ""
    notice.primary_firstname = recipient.first_name.titleize || ""
    notice.past_due_text = "PAST DUE"
    if recipient.mailing_address
      append_address(recipient.mailing_address)
    else
      raise 'mailing address not present'
    end
  end

  def find_transition_people(people_ids)
    @transition_people = []
    people_ids.each do |person_id|
      @transition_people << Person.find(person_id)
    end

  end

  def check_for_transitioned_individuals
    @transition_people.each do |person|
      notice.individuals << PdfTemplates::Individual.new({
                                                             :first_name => person.first_name.titleize,
                                                             :last_name => person.last_name.titleize,
                                                             :age => calculate_age_by_dob(person.dob),
                                                         })
    end
  end

  def check_for_unverified_individuals
    family = recipient.primary_family
    date = TimeKeeper.date_of_record
    enrollments = HbxEnrollment.where(family_id: family.id).select do |hbx_en|
      (!hbx_en.is_shop?) && (!["coverage_canceled", "shopping", "inactive"].include?(hbx_en.aasm_state)) &&
          (hbx_en.terminated_on.blank? || hbx_en.terminated_on >= TimeKeeper.date_of_record)
    end
    enrollments.reject!{|e| e.coverage_terminated? }

    hbx_enrollments = []
    en = enrollments.select{ |en| HbxEnrollment::ENROLLED_STATUSES.include?(en.aasm_state)}
    health_enrollments = en.select{ |e| e.coverage_kind == "health"}.sort_by(&:effective_on)
    dental_enrollments = en.select{ |e| e.coverage_kind == "dental"}.sort_by(&:effective_on)
    hbx_enrollments << health_enrollments
    hbx_enrollments << dental_enrollments
    hbx_enrollments.flatten!
    hbx_enrollments.compact!

    hbx_enrollments.each do |enrollment|
      notice.enrollments << append_enrollment_information(enrollment)
    end
    notice.coverage_year = hbx_enrollments.compact.first.effective_on.year
  end

  def append_unverified_individuals
    @transition_people.each do |person|
      person.consumer_role.expired_verification_types.each do |verification_type|
        case verification_type.type_name
        when "Social Security Number"
          notice.ssa_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, past_due_text: "PAST DUE", age: person.age_on(TimeKeeper.date_of_record) })
        when "Immigration status"
          notice.immigration_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, past_due_text: "PAST DUE", age: person.age_on(TimeKeeper.date_of_record) })
        when "Citizenship"
          notice.dhs_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, past_due_text: "PAST DUE", age: person.age_on(TimeKeeper.date_of_record) })
        when "American Indian Status"
          notice.american_indian_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, past_due_text: "PAST DUE", age: person.age_on(TimeKeeper.date_of_record) })
        when "DC Residency"
          notice.residency_inconsistency << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, past_due_text: "PAST DUE", age: person.age_on(TimeKeeper.date_of_record) })
        end
      end
    end
  end

  def append_enrollment_information(enrollment)
    plan = PdfTemplates::Plan.new({
                                    plan_name: enrollment.product.title,
                                    is_csr: enrollment.product.is_csr?,
                                    coverage_kind: enrollment.product.kind,
                                    plan_carrier: enrollment.product.issuer_profile.organization.legal_name,
                                    family_deductible: enrollment.product.family_deductible.split("|").last.squish,
                                    deductible: enrollment.product.deductible
                                  })
    PdfTemplates::Enrollment.new({
     created_at: enrollment.created_at,
     premium: enrollment.total_premium.round(2),
     aptc_amount: enrollment.applied_aptc_amount.round(2),
     responsible_amount: (enrollment.total_premium - enrollment.applied_aptc_amount.to_f).round(2),
     phone: phone_number(enrollment.product.issuer_profile.legal_name),
     is_receiving_assistance: enrollment.applied_aptc_amount > 0 || enrollment.product.is_csr? ? true : false,
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


  def phone_number(legal_name)
    case legal_name
    when "BestLife"
      "(800) 433-0088"
    when "CareFirst BCBS"
      "(855) 444-3119"
    when "Delta Dental"
      "(800) 471-0236"
    when "Dominion"
      "(855) 224-3016"
    when "Kaiser"
      "(844) 524-7370"
    end
  end


end