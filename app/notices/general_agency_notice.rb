class GeneralAgencyNotice < Notice
  
  Required = Notice::Required + []

  attr_accessor :employer_profile, :general_agency_profile, :general_agent

  def initialize(employer_profile, args = {})
    self.employer_profile = employer_profile
    self.general_agency_profile = employer_profile.general_agency_accounts.inactive.last.general_agency_profile
    self.general_agent = general_agency_profile.primary_staff.person
    args[:recipient] = general_agency_profile
    args[:market_kind]= 'shop'
    args[:notice] = PdfTemplates::GeneralAgencyNotice.new
    args[:to] = general_agent.work_email_or_best
    args[:name] = general_agent.full_name
    args[:recipient_document_store] = general_agency_profile
    self.header = "notices/shared/shop_header.html.erb"
    super(args)
  end

  def deliver
    build
    generate_pdf_notice
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def build
    notice.primary_fullname = general_agency_profile.legal_name.titleize
    notice.ga_email = general_agent.work_email_or_best
    notice.mpi_indicator = self.mpi_indicator
    notice.employer_name = employer_profile.legal_name.titleize
    notice.terminated_on = employer_profile.general_agency_accounts.inactive.last.end_on
    append_hbe
    append_address(general_agency_profile.organization.primary_office_location.address)
  end

  def attach_envelope
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'taglines.pdf')]
  end

  def non_discrimination_attachment
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'shop_non_discrimination_attachment.pdf')]
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

  def append_hbe
    notice.hbe = PdfTemplates::Hbe.new({
     url: "www.dhs.dc.gov",
     phone: "(855) 532-5465",
     fax: "(855) 532-5465",
     email: "#{Settings.contact_center.email_address}"
     })
  end
end