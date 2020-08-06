# frozen_string_literal: true

class IvlNotices::IvlRenewalNotice < IvlNotice
  attr_accessor :family, :data, :person, :open_enrollment_start_on, :open_enrollment_end_on

  def initialize(consumer_role, args = {})
    args[:recipient] = consumer_role.person
    args[:notice] = PdfTemplates::ConditionalEligibilityNotice.new
    args[:market_kind] = 'individual'
    args[:recipient_document_store] = consumer_role.person
    args[:to] = consumer_role.person.work_email_or_best
    self.person = args[:person]
    self.open_enrollment_start_on = args[:open_enrollment_start_on]
    self.open_enrollment_end_on = args[:open_enrollment_end_on]
    self.data = args[:data]
    self.header = "notices/shared/header_ivl.html.erb"
    super(args)
  end

  def deliver
    build
    generate_pdf_notice
    attach_blank_page
    attach_non_discrimination
    attach_taglines
    attach_voter_application
    upload_and_send_secure_message

    send_generic_notice_alert if recipient.consumer_role.can_receive_electronic_communication?

    store_paper_notice if recipient.consumer_role.can_receive_paper_communication?
  end

  def build
    append_hbe
    notice.notification_type = self.event_name
    notice.mpi_indicator = self.mpi_indicator
    notice.ivl_open_enrollment_start_on = open_enrollment_start_on
    notice.ivl_open_enrollment_end_on = open_enrollment_end_on
    notice.coverage_year = TimeKeeper.date_of_record.next_year.year
    notice.primary_firstname = person.first_name
    family = recipient.primary_family
    append_data
    notice.primary_fullname = recipient.full_name.titleize || ""
    if recipient.mailing_address
      append_address(recipient.mailing_address)
    else
      # @notice.primary_address = nil
      raise 'mailing address not present'
    end
  end

  def append_data
    notice.individuals = data.collect do |datum|
      person = Person.where(:hbx_id => datum["policy.subscriber.person.hbx_id"]).first
      PdfTemplates::Individual.new({
                                     :first_name => person.first_name,
                                     :full_name => person.full_name,
                                     :last_name => person.last_name,
                                     :age => person.age_on(TimeKeeper.date_of_record),
                                     :is_without_assistance => true,
                                     :incarcerated => datum["policy.subscriber.person.is_incarcerated"] == "TRUE" ? "Yes" : "No", #Per Sarah, for blank incarceration, fill in FALSE
                                     :citizen_status => citizen_status(datum["policy.subscriber.person.citizen_status"]),
                                     :residency_verified => datum["policy.subscriber.person.is_dc_resident?"].try(:upcase) == "TRUE" ? "Yes" : "No"
                                   })
    end
  end

  def citizen_status(status)
    case status
    when "us_citizen"
      "US Citizen"
    when "alien_lawfully_present"
      "Lawfully Present"
    when "indian_tribe_member"
      "US Citizen"
    when "lawful_permanent_resident"
      "Lawfully Present"
    when "naturalized_citizen"
      "US Citizen"
    else
      "Ineligible Immigration Status"
    end
  end

end