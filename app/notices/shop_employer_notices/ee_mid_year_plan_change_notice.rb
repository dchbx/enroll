class ShopEmployerNotices::EeMidYearPlanChangeNotice < ShopEmployerNotice

  attr_accessor :employer_profile, :hbx_enrollment

  def initialize(employer_profile, args = {})
    self.hbx_enrollment = HbxEnrollment.by_hbx_id(args[:options][:hbx_enrollment]).first
    super(employer_profile, args)
  end

  def deliver
    build
    append_data
    generate_pdf_notice
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert unless self.hbx_enrollment.benefit_group.is_congress
    send_generic_notice_alert_to_broker_and_ga
  end

  def append_data
    effective_on = self.hbx_enrollment.effective_on
    employee_fullname = self.hbx_enrollment.employee_role.person.full_name.titleize
  	notice.enrollment = PdfTemplates::Enrollment.new({
      :effective_on => effective_on
      })
    notice.employee = PdfTemplates::EmployeeNotice.new({
      :primary_fullname => employee_fullname
      })
  end
end