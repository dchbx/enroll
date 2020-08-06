# frozen_string_literal: true

class IvlNotices::ReminderNotice < IvlNotice
  attr_accessor :family

  def initialize(consumer_role, args = {})
    args[:recipient] = consumer_role.person
    args[:notice] = PdfTemplates::ConditionalEligibilityNotice.new
    args[:market_kind] = 'individual'
    args[:recipient_document_store] = consumer_role.person
    args[:to] = consumer_role.person.work_email_or_best
    self.header = "notices/shared/header_ivl.html.erb"
    super(args)
  end

  def deliver
    build
    generate_pdf_notice
    attach_blank_page(notice_path)
    attach_required_documents if notice.documents_needed && !notice.cover_all?
    attach_non_discrimination
    attach_taglines
    upload_and_send_secure_message

    send_generic_notice_alert if recipient.consumer_role.can_receive_electronic_communication?

    store_paper_notice if recipient.consumer_role.can_receive_paper_communication?
    clear_tmp(notice_path)
  end

  def attach_required_documents
    generate_custom_notice('notices/ivl/documents_section')
    attach_blank_page(custom_notice_path)
    join_pdfs [notice_path, custom_notice_path]
    clear_tmp(custom_notice_path)
  end

  def build
    notice.mpi_indicator = self.mpi_indicator
    notice.notification_type = self.event_name
    notice.primary_fullname = recipient.full_name.titleize || ""
    notice.first_name = recipient.first_name
    notice.primary_identifier = recipient.hbx_id
    append_hbe
    append_unverified_family_members
    append_notice_subject

    if recipient.mailing_address
      append_address(recipient.mailing_address)
    else
      raise 'mailing address not present'
    end
  end

  def append_notice_subject
    notice.notice_subject = case notice.notification_type
                            when "first_verifications_reminder"
                              "REMINDER - KEEPING YOUR INSURANCE - SUBMIT DOCUMENTS BY #{notice.due_date.strftime('%^B %d, %Y')}"
                            when "second_verifications_reminder"
                              "DON’T FORGET – YOU MUST SUBMIT DOCUMENTS BY #{notice.due_date.strftime('%^B %d, %Y')} TO KEEP YOUR INSURANCE"
                            when "third_verifications_reminder"
                              "DON’T MISS THE DEADLINE – YOU MUST SUBMIT DOCUMENTS BY #{notice.due_date.strftime('%^B %d, %Y')} TO KEEP YOUR INSURANCE"
                            when "fourth_verifications_reminder"
                              "FINAL NOTICE – YOU MUST SUBMIT DOCUMENTS BY #{notice.due_date.strftime('%^B %d, %Y')} TO KEEP YOUR INSURANCE"
    end
  end

  def append_unverified_family_members
    family = recipient.primary_family
    enrollments = HbxEnrollment.where(family_id: family.id).select do |hbx_en|
      !hbx_en.is_shop? && !["coverage_canceled", "shopping", "inactive"].include?(hbx_en.aasm_state) &&
        (
          hbx_en.terminated_on.blank? ||
          hbx_en.terminated_on >= TimeKeeper.date_of_record
        )
    end
    enrollments.reject!(&:coverage_terminated?)
    raise 'enrollments not found!' if enrollments.empty?
    family_members = enrollments.inject([]) do |family_members, enrollment|
      family_members += enrollment.hbx_enrollment_members.map(&:family_member)
    end.uniq
    people = family_members.map(&:person).uniq
    people.select!{|p| p.consumer_role.aasm_state == 'verification_outstanding'}
    people.select!{|person| person.consumer_role.types_include_to_notices.present? }
    raise 'no family member found with outstanding verification types or verification_outstanding status' if people.empty?

    outstanding_people = []
    people.each do |person|
      outstanding_people << person if person.consumer_role.types_include_to_notices.present?
    end

    outstanding_people.uniq!
    raise 'no family member found without uploaded documents' if outstanding_people.empty?

    hbx_enrollments = []
    en = enrollments.select(&:is_any_enrollment_member_outstanding)
    health_enrollments = en.select{ |e| e.coverage_kind == "health"}.sort_by(&:created_at)
    dental_enrollments = en.select{ |e| e.coverage_kind == "dental"}.sort_by(&:created_at)
    hbx_enrollments << health_enrollments
    hbx_enrollments << dental_enrollments
    hbx_enrollments.flatten!
    hbx_enrollments.compact!

    hbx_enrollments.each do |enrollment|
      notice.enrollments << build_enrollment(enrollment)
    end

    notice.documents_needed = outstanding_people.present? ? true : false
    notice.due_date = family.min_verification_due_date
    notice.application_date = hbx_enrollments.max_by(&:created_at).created_at.to_date
    append_unverified_individuals(outstanding_people)
  end

  def build_enrollment(hbx_enrollment)
    PdfTemplates::Enrollment.new({
                                   plan_name: hbx_enrollment.product.title,
                                   premium: hbx_enrollment.total_premium,
                                   phone: hbx_enrollment.phone_number,
                                   coverage_kind: hbx_enrollment.coverage_kind,
                                   effective_on: hbx_enrollment.effective_on,
                                   selected_on: hbx_enrollment.created_at,
                                   is_receiving_assistance: hbx_enrollment.applied_aptc_amount > 0 || hbx_enrollment.product.is_csr? ? true : false
                                 })
  end

  def ssn_outstanding?(person)
    person.consumer_role.types_include_to_notices.map(&:type_name).include?("Social Security Number")
  end

  def citizenship_outstanding?(person)
    person.consumer_role.types_include_to_notices.map(&:type_name).include?('Citizenship')
  end

  def immigration_outstanding?(person)
    person.consumer_role.types_include_to_notices.map(&:type_name).include?('Immigration status')
  end

  def residency_outstanding?(person)
    person.consumer_role.types_include_to_notices.map(&:type_name).include?('DC Residency')
  end

  def append_unverified_individuals(people)
    people.each do |person|
      person.consumer_role.types_include_to_notices.each do |verification_type|
        case verification_type.type_name
        when "Social Security Number"
          notice.ssa_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: verification_type.due_date, age: person.age_on(TimeKeeper.date_of_record) })
        when "Immigration status"
          notice.immigration_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: verification_type.due_date, age: person.age_on(TimeKeeper.date_of_record) })
        when "Citizenship"
          notice.dhs_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: verification_type.due_date, age: person.age_on(TimeKeeper.date_of_record) })
        when "American Indian Status"
          notice.american_indian_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: verification_type.due_date, age: person.age_on(TimeKeeper.date_of_record) })
        when "DC Residency"
          notice.residency_inconsistency << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: verification_type.due_date, age: person.age_on(TimeKeeper.date_of_record) })
        end
      end
    end
  end

  def append_address(primary_address)
    notice.primary_address = PdfTemplates::NoticeAddress.new({
                                                               street_1: capitalize_quadrant(primary_address.address_1.to_s.titleize),
                                                               street_2: capitalize_quadrant(primary_address.address_2.to_s.titleize),
                                                               city: primary_address.city.titleize,
                                                               state: primary_address.state,
                                                               zip: primary_address.zip
                                                             })
  end

  def append_hbe
    notice.hbe = PdfTemplates::Hbe.new({
                                         url: Settings.site.home_url,
                                         phone: phone_number_format(Settings.contact_center.phone_number),
                                         email: Settings.contact_center.email_address,
                                         short_url: "#{Settings.site.short_name.gsub(/[^0-9a-z]/i,'').downcase}.com"
                                       })
  end

  def capitalize_quadrant(address_line)
    address_line.split(/\s/).map do |x|
      x.strip.match(/^NW$|^NE$|^SE$|^SW$/i).present? ? x.strip.upcase : x.strip
    end.join(' ')
  end

  def to_csv
    [
      recipient.hbx_id,
      recipient.first_name,
      recipient.last_name,
      notice.primary_address.present? ? notice.primary_address.attributes.values.reject(&:blank?).compact.join(',') : "",
      notice.due_date,
      (notice.enrollments.first.submitted_at || notice.enrollments.first.created_at),
      notice.enrollments.first.effective_on,
      notice.ssa_unverified.map(&:full_name).join(','),
      notice.dhs_unverified.map(&:full_name).join(','),
      recipient.consumer_role.contact_method,
      recipient.home_email.try(:address) || recipient.user.try(:email),
      notice.enrollments.first.aasm_state.to_s
    ]
  end
end