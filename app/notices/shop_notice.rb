class ShopNotice < Notice

  Required= Notice::Required + []

  attr_accessor :employer_profile

  def initialize(employer_profile, args = {})
    self.employer_profile = employer_profile
    args[:recipient] = employer_profile
    args[:market_kind]= 'shop'
    args[:notice] = PdfTemplates::EmployerNotice.new
    args[:to] = employer_profile.staff_roles.first.work_email_or_best
    args[:name] = "testing"
    args[:recipient_document_store]= employer_profile
    self.header = "notices/shared/header_with_page_numbers.html.erb"
    super(args)
  end

  def deliver
    build
    generate_pdf_notice
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def build
    notice.primary_fullname = employer_profile.staff_roles.first.full_name.titleize
    notice.employer_name = recipient.organization.legal_name.titleize
    notice.primary_identifier = employer_profile.hbx_id
    append_address(employer_profile.organization.primary_office_location.address)
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
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'envelope_without_address.pdf')]
  end

  def append_address(primary_address)
    notice.primary_address = PdfTemplates::NoticeAddress.new({
      street_1: primary_address.address_1.titleize,
      street_2: primary_address.address_2.titleize,
      city: primary_address.city.titleize,
      state: primary_address.state,
      zip: primary_address.zip
      })
  end

  def append_broker(broker)
    return if broker.blank?
    location = broker.organization.primary_office_location
    broker_role = broker.primary_broker_role
    person = broker_role.person if broker_role
    return if person.blank? || location.blank?
    
    notice.broker = PdfTemplates::Broker.new({
      primary_fullname: person.full_name,
      organization: broker.legal_name,
      phone: location.phone.try(:to_s),
      email: (person.home_email || person.work_email).try(:address),
      web_address: broker.home_page,
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
