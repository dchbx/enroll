class ShopEmployeeNotices::RenewalEmployeeEnrollmentConfirmation < ShopEmployeeNotice

  attr_accessor :census_employee

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
    health_enrs, dental_enrs = census_employee.renewal_benefit_group_assignment.hbx_enrollments.partition{|enr| enr.coverage_kind == "health"}
    
    enrollment = health_enrs.first
    if enrollment.present?
      notice.enrollment = PdfTemplates::Enrollment.new({
        :employer_contribution => enrollment.total_employer_contribution,
        :employee_cost => enrollment.total_employee_cost,
        :effective_on => enrollment.effective_on
      })

      plan = enrollment.plan
      notice.plan = PdfTemplates::Plan.new({
        :plan_name => plan.name
      })
    end

    dental_enrollment = dental_enrs.first
    if dental_enrollment.present?
      notice.dental_enrollment = PdfTemplates::Enrollment.new({ 
        :employer_contribution => dental_enrollment.total_employer_contribution,
        :employee_cost => dental_enrollment.total_employee_cost,
        :effective_on => dental_enrollment.effective_on
        })
      dental_plan = dental_enrollment.plan
      notice.dental_plan = PdfTemplates::Plan.new({
        :plan_name => dental_plan.name
      })
    end
  end
end
