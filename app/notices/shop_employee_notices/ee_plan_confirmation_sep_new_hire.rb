class ShopEmployeeNotices::EePlanConfirmationSepNewHire < ShopEmployeeNotice

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
    hbx_enrollment = self.hbx_enrollment
    notice.enrollment = PdfTemplates::Enrollment.new({
       :effective_on => hbx_enrollment.effective_on,
       :plan => {:plan_name => hbx_enrollment.plan.name},
       :employee_cost => hbx_enrollment.total_employee_cost,
       :employer_contribution => hbx_enrollment.total_employer_contribution
       })
  end
end