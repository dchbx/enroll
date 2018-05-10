class ShopEmployerNotices::NoticeToEmployerNoBinderPaymentReceived < ShopEmployerNotice

  def deliver
	    build
	    append_data
	    generate_pdf_notice
	    attach_envelope
	    non_discrimination_attachment
	    upload_and_send_secure_message
	    send_generic_notice_alert
  end

  def append_data
    plan_year = employer_profile.plan_years.where(:aasm_state.in => PlanYear::INITIAL_ENROLLING_STATE).first

    #plan = plan_year.reference_plan
    notice.plan_year = PdfTemplates::PlanYear.new({
                       :start_on => plan_year.start_on
        })
    #binder payment deadline
    notice.plan_year.binder_payment_due_date = PlanYear.calculate_open_enrollment_date(plan_year.start_on)[:binder_payment_due_date]
      payment = employer_profile.show_plan_year.benefit_groups.map(&:monthly_employer_contribution_amount )
     notice.plan_year.binder_payment_total = payment.inject(0){ |sum,a| sum+a }
  end
end