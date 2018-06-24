class ShopEmployerNotices::GroupAdvanceTerminationConfirmation < ShopEmployerNotice
 
   def deliver
     build
     append_data
     generate_pdf_notice
     non_discrimination_attachment
     attach_envelope
     upload_and_send_secure_message
     send_generic_notice_alert
     send_generic_notice_alert_to_broker_and_ga
   end
 
   def append_data
     plan_year = employer_profile.plan_years.where(:aasm_state => "terminated").sort_by(&:start_on).last
     notice.plan_year = PdfTemplates::PlanYear.new({ end_on: plan_year.end_on })
   end
 
end 
