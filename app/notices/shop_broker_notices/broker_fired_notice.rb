class ShopBrokerNotices::BrokerFiredNotice < ShopBrokerNotice
  Required= Notice::Required + []

  attr_accessor :broker
  attr_accessor :employer_profile

  def initialize(employer_profile, args = {})
    self.employer_profile = employer_profile
    broker_role = employer_profile.broker_agency_accounts.unscoped.last.broker_agency_profile.primary_broker_role.person
    self.broker = broker_role
    args[:recipient] = broker
    args[:market_kind]= 'shop'
    args[:notice] = PdfTemplates::BrokerNotice.new
    args[:to] = broker.work_email_or_best
    args[:name] = broker.full_name
    args[:recipient_document_store] = broker
    self.header = "notices/shared/shop_header.html.erb"
    super(employer_profile, args)
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
    notice.primary_fullname = broker.full_name.titleize
    notice.first_name = broker.first_name.titleize
    notice.last_name = broker.last_name.titleize
    notice.hbx_id = broker.hbx_id
    notice.mpi_indicator = self.mpi_indicator
    notice.employer_name = employer_profile.legal_name.titleize
    notice.employer_first_name = employer_profile.staff_roles.first.first_name.titleize
    notice.employer_last_name = employer_profile.staff_roles.first.last_name.titleize
    notice.termination_date = employer_profile.broker_agency_accounts.unscoped.last.end_on
    notice.broker_agency = employer_profile.broker_agency_accounts.unscoped.last.broker_agency_profile.legal_name.titleize
    append_hbe

    organization = employer_profile.broker_agency_accounts.unscoped.last.broker_agency_profile.organization
    address = organization.primary_mailing_address.present? ? organization.primary_mailing_address : organization.primary_office_location.address
    append_address(address)
  end

end