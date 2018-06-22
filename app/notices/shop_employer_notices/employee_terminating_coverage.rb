class ShopEmployerNotices::EmployeeTerminatingCoverage < ShopEmployerNotice

  attr_accessor :hbx_enrollment

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
    send_generic_notice_alert
  end

  def append_data
    employee_fullname =  hbx_enrollment.employee_role.person.full_name.titleize
    notice.enrollment = PdfTemplates::Enrollment.new({
      :terminated_on => hbx_enrollment.terminated_on,
      :enrolled_count => hbx_enrollment.humanized_dependent_summary,
      :employee_fullname => employee_fullname
      })
  end
end
