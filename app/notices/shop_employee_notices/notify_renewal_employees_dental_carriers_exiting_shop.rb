class ShopEmployeeNotices::NotifyRenewalEmployeesDentalCarriersExitingShop < ShopEmployeeNotice
  attr_accessor :census_employee, :hbx_enrollment

  def initialize(census_employee, args = {})
    self.hbx_enrollment = HbxEnrollment.by_hbx_id(args[:options][:hbx_enrollment]).first
    super(census_employee, args)
  end

  def deliver
    build
    append_data
    generate_pdf_notice
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def append_data
    plan = self.hbx_enrollment.plan
    plan_name = plan.name
    plan_year_start_on = self.hbx_enrollment.benefit_group.plan_year.start_on
    plan_year_end_on = self.hbx_enrollment.benefit_group.plan_year.end_on
    carrier_name = plan.carrier_profile.organization.legal_name
    primary_fullname = self.hbx_enrollment.employee_role.person.full_name
    primary_email = self.hbx_enrollment.employee_role.person.work_email_or_best

    notice.plan = PdfTemplates::Plan.new({
      :plan_name => hbx_enrollment.plan.name,
      :coverage_start_on => plan_year_start_on,
      :coverage_end_on => plan_year_end_on,
      :plan_carrier => carrier_name
      })
    
    notice.primary_fullname = primary_fullname
    notice.email = primary_email
  end
end