class ShopEmployeeNotices::EmployeeSelectPlanDuringOpenEnrollment < ShopEmployeeNotice

  attr_accessor :census_employee, :hbx_enrollment

  def initialize(census_employee, args = {})
    self.hbx_enrollment = HbxEnrollment.by_hbx_id(args[:options][:hbx_enrollment_hbx_id]).first
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
    hbx_enrollment = self.hbx_enrollment
    notice.enrollment = PdfTemplates::Enrollment.new({
      :employer_contribution => hbx_enrollment.total_employer_contribution,
      :employee_cost => hbx_enrollment.total_employee_cost,
      :effective_on => hbx_enrollment.effective_on
      })

    plan = hbx_enrollment.plan
    notice.plan = PdfTemplates::Plan.new({
      :plan_name => plan.name
      })
  end
end
