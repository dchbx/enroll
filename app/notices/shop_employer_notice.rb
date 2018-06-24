class ShopEmployerNotice < Notice

  Required= Notice::Required + []

  attr_accessor :employer_profile, :key

  def initialize(employer_profile, args = {})
    self.employer_profile = employer_profile
    args[:recipient] = employer_profile
    args[:market_kind]= 'shop'
    args[:notice] = PdfTemplates::EmployerNotice.new
    args[:to] = employer_profile.staff_roles.first.work_email_or_best
    args[:name] = employer_profile.staff_roles.first.full_name.titleize
    args[:recipient_document_store]= employer_profile
    self.header = "notices/shared/shop_header.html.erb" 
    self.key = args[:key]
    super(args)
  end

  def deliver
    build
    generate_pdf_notice
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
    send_generic_notice_alert_to_broker_and_ga
  end

  def build
    notice.mpi_indicator = self.mpi_indicator
    notice.notification_type = self.event_name
    notice.primary_fullname = employer_profile.staff_roles.first.full_name.titleize
    notice.employer_name = recipient.organization.legal_name.titleize
    notice.employer_email = recipient.staff_roles.first.work_email_or_best
    notice.primary_identifier = employer_profile.hbx_id
    address = employer_profile.organization.primary_mailing_address.present? ? employer_profile.organization.primary_mailing_address : employer_profile.organization.primary_office_location.address
    append_address(address)
    append_hbe
    append_broker(employer_profile.broker_agency_profile)
  end

  def append_hbe
    notice.hbe = PdfTemplates::Hbe.new({
      url: "www.dhs.dc.gov",
      phone: "(855) 532-5465",
      fax: "(855) 532-5465",
      email: "#{Settings.contact_center.email_address}",
      address: PdfTemplates::NoticeAddress.new({
        street_1: "100 K ST NE",
        street_2: "Suite 100",
        city: "Washington DC",
        state: "DC",
        zip: "20005"
      })
    })
  end

  def attach_envelope
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'taglines.pdf')]
  end

  def shop_dchl_rights_attachment
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'shop_dchl_rights.pdf')]
  end

  def non_discrimination_attachment
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'shop_non_discrimination_attachment.pdf')]
  end

  def append_address(address)
    notice.primary_address = PdfTemplates::NoticeAddress.new({
      street_1: address.address_1.titleize,
      street_2: address.address_2.titleize,
      city: address.city.titleize,
      state: address.state,
      zip: address.zip
      })
  end

  def send_generic_notice_alert_to_broker_and_ga
    if employer_profile.broker_agency_profile.present?
      broker_name = employer_profile.broker_agency_profile.primary_broker_role.person.full_name.titleize
      broker_email = employer_profile.broker_agency_profile.primary_broker_role.email_address
      UserMailer.generic_notice_alert_to_ba_and_ga(broker_name, broker_email, employer_profile.legal_name.titleize).deliver_now
    end
    if employer_profile.general_agency_profile.present?
      ga_staff_name = employer_profile.general_agency_profile.general_agency_staff_roles.first.person.full_name.titleize
      ga_staff_email = employer_profile.general_agency_profile.general_agency_staff_roles.first.email_address
      UserMailer.generic_notice_alert_to_ba_and_ga(ga_staff_name, ga_staff_email, employer_profile.legal_name.titleize).deliver_now
    end
  end

  def append_broker(broker)
    return if broker.blank?
    location = broker.organization.primary_office_location
    broker_role = broker.primary_broker_role
    person = broker_role.person if broker_role
    return if person.blank? || location.blank?

    notice.broker = PdfTemplates::Broker.new({
      primary_fullname: person.full_name.titleize,
      organization: broker.legal_name,
      phone: location.phone.try(:to_s),
      email: (person.home_email || person.work_email).try(:address),
      web_address: broker.home_page,
      first_name: person.first_name,
      last_name: person.last_name,
      assignment_date: employer_profile.active_broker_agency_account.present? ? employer_profile.active_broker_agency_account.start_on : "",
      address: PdfTemplates::NoticeAddress.new({
        street_1: location.address.address_1,
        street_2: location.address.address_2,
        city: location.address.city,
        state: location.address.state,
        zip: location.address.zip
      })
    })
  end

end