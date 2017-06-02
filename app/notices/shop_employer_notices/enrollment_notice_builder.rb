class ShopEmployerNotices::EnrollmentNoticeBuilder < ShopEmployerNotice

  attr_reader :notice, :to
  
  def initialize(employer, args = {})
    super(args)
    @employer = employer
    @to = @employer.try(:person).try(:home_email).try(:address)
    @template = args[:template] || "notices/shop_employer_notices/shop_5c_notice.html.erb"
    @email_notice = args[:email_notice] || true
    @paper_notice = args[:paper_notice] || true
    build
  end

  def build
    @notice = PdfTemplates::EmployerNotice.new
    @notice.to = @to
    @notice.primary_fullname = @employer.person.full_name.titleize
    employer_profile = EmployerProfile.find(@employer.employer_profile_id)
    @notice.primary_identifier = employer_profile.organization.hbx_id
    @notice.open_enrollment_end_on = employer_profile.try(:active_plan_year).try(:open_enrollment_end_on)
    @notice.coverage_end_on = employer_profile.try(:active_plan_year).try(:end_on)
    if @employer.person.mailing_address.present?
      append_primary_address(@employer.person.mailing_address)
    else
      append_primary_address(employer_profile.organization.try(:primary_office_location).try(:address))
    end

    append_hbe
    append_broker(employer_profile.broker_agency_profile)
    plan_year = employer_profile.active_plan_year || employer_profile.latest_plan_year
    append_plan(plan_year)
  end

  def append_plan(plan_year)
    @notice.plan = PdfTemplates::Plan.new({
      open_enrollment_start_on: plan_year.open_enrollment_start_on,
      open_enrollment_end_on: plan_year.open_enrollment_end_on,
      coverage_start_on: plan_year.start_on,
      coverage_end_on: plan_year.end_on
    })
  end
  
  def append_broker(broker)
    return if broker.blank?
    location = broker.organization.primary_office_location
    broker_role = broker.primary_broker_role
    @notice.broker = PdfTemplates::Broker.new({
      primary_fullname: broker_role.try(:person).try(:full_name),
      organization: broker.legal_name,
      phone: location.phone.try(:to_s),
      email: broker_role.email_address,
      web_address: broker.home_page,
      address: PdfTemplates::NoticeAddress.new({
        street_1: location.try(:address).try(:address_1),
        street_2: location.try(:address).try(:address_2),
        city: location.try(:address).try(:city),
        state: location.try(:address).try(:state),
        zip: location.try(:address).try(:zip)
      })
    })
  end
end