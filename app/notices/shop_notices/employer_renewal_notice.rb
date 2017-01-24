class ShopNotices::EmployerRenewalNotice < ShopNotice

  attr_accessor :employer_profile

  Required= ShopNotice::Required + [:employer_profile]

  def initialize(args = {})
    self.employer_profile=args[:employer_profile]
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
    super
  end

  def build
    notice.primary_fullname = employer_profile.staff_roles.first.full_name.titleize
    notice.employer_name = recipient.organization.legal_name.titleize
    notice.primary_identifier = employer_profile.hbx_id
    append_address(employer_profile.organization.primary_office_location.address)
    append_hbe
    append_broker(employer_profile.broker_agency_profile)
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

end
