# frozen_string_literal: true

class IvlNotices::IvlBacklogVerificationNoticeUqhp < IvlNotice
  include ApplicationHelper
  attr_accessor :family, :data, :person

  def initialize(_consumer_role, args = {})
    args[:recipient] = args[:family].primary_applicant.person
    args[:notice] = PdfTemplates::ConditionalEligibilityNotice.new
    args[:market_kind] = 'individual'
    args[:recipient_document_store] = args[:family].primary_applicant.person
    args[:to] = args[:family].primary_applicant.person.work_email_or_best
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

    send_generic_notice_alert if recipient.consumer_role.can_receive_electronic_communication?

    store_paper_notice if recipient.consumer_role.can_receive_paper_communication?
    clear_tmp(notice_path)
  end

  def build
    append_data
    check_for_unverified_individuals
    append_hbe
    if recipient.mailing_address
      append_address(recipient.mailing_address)
    else
      raise 'mailing address not present'
    end
  end

  def check_for_unverified_individuals
    family = recipient.primary_family
    enrollments = HbxEnrollment.where(family_id: family.id, :is_any_enrollment_member_outstanding => true,
                                      :effective_on => { :"$gte" => TimeKeeper.date_of_record.beginning_of_year, :"$lte" => TimeKeeper.date_of_record.end_of_year },
                                      :kind => "individual")
    family_members = enrollments.inject([]) do |family_members, enrollment|
      family_members += enrollment.hbx_enrollment_members.map(&:family_member)
    end.uniq
    people = family_members.map(&:person).uniq
    outstanding_people = []
    people.each do |person|
      outstanding_people << person if person.consumer_role.outstanding_verification_types.present?
    end
    notice.due_date = family.min_verification_due_date
    outstanding_people.uniq!
    notice.documents_needed = outstanding_people.present? ? true : false
    append_unverified_individuals(outstanding_people)
  end

  def append_unverified_individuals(people)
    people.each do |person|
      person.consumer_role.outstanding_verification_types.each do |verification_type|
        case verification_type.type_name
        when "Social Security Number"
          notice.ssa_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: notice.due_date, age: person.age_on(TimeKeeper.date_of_record) })
        when "Immigration status"
          notice.immigration_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: notice.due_date, age: person.age_on(TimeKeeper.date_of_record) })
        when "Citizenship"
          notice.dhs_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: notice.due_date, age: person.age_on(TimeKeeper.date_of_record) })
        when "American Indian Status"
          notice.american_indian_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: notice.due_date, age: person.age_on(TimeKeeper.date_of_record) })
        when "DC Residency"
          notice.residency_inconsistency << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: notice.due_date, age: person.age_on(TimeKeeper.date_of_record) })
        end
      end
    end
  end

  def append_data
    notice.notification_type = self.event_name
    notice.mpi_indicator = self.mpi_indicator
    notice.primary_identifier = recipient.hbx_id
    notice.coverage_year = TimeKeeper.date_of_record.year
    notice.current_year = TimeKeeper.date_of_record.year
    notice.primary_fullname = recipient.full_name.titleize || ""
    notice.primary_firstname = recipient.first_name.titleize
  end

end