class ShopNotices::EmployerNotice < ShopNotice

  attr_accessor :employer_profile,:trigger_type

  Required= ShopNotice::Required + [:employer_profile]

  def initialize(args = {})
    self.employer_profile=args[:employer_profile]
    self.trigger_type = args[:trigger_type]
    args[:recipient] = employer_profile
    args[:market_kind]= 'shop'
    args[:notice] = PdfTemplates::EmployerNotice.new
    args[:to] = employer_profile.staff_roles.first.work_email_or_best
    args[:name] = "testing"
    args[:recipient_document_store]= employer_profile
    self.header = "notices/shared/header_with_page_numbers.html.erb"
    super(args)
    
    # @email_notice = args[:email_notice] || true
    # @paper_notice = args[:paper_notice] || true
  end

  def deliver
    # send_email_notice if @email_notice
    # send_pdf_notice if @paper_notice
    # send_email_notice
    build
    super
  end

  def build
    notice.trigger_type = self.trigger_type
    notice.primary_fullname = employer_profile.staff_roles.first.full_name.titleize
    notice.employer_name = recipient.organization.legal_name.titleize
    notice.primary_identifier = employer_profile.hbx_id
    append_address(employer_profile.organization.primary_office_location.address)
    # @notice.open_enrollment_end_on = employer_profile.try(:active_plan_year).try(:open_enrollment_end_on)
    # @notice.coverage_end_on = employer_profile.try(:active_plan_year).try(:end_on)
    # @notice.coverage_start_on = employer_profile.plan_years.sort_by{|start_on| start_on}.last.start_on
    # if @recipient.mailing_address.present?

    # append_primary_address(recipient.mailing_address || employer_profile.organization.office_locations.first.address)

    # else
    #   append_primary_address(employer_profile.organization.try(:primary_office_location).try(:address))
    # end

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
