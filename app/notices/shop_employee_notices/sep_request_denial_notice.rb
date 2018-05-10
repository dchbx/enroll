class ShopEmployeeNotices::SepRequestDenialNotice < ShopEmployeeNotice

  attr_accessor :census_employee, :qle, :qle_reported_date

  def initialize(census_employee, args = {})
    self.qle = QualifyingLifeEventKind.find(args[:options][:qle_id])
    self.qle_reported_date = args[:options][:qle_reported_date]
    super(census_employee, args)
  end

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
  	title = self.qle.title
    qle_reported_on = TimeKeeper.date_of_record
    qle_on = Date.strptime(self.qle_reported_date.to_s, "%m/%d/%Y").to_date
  	reporting_deadline = qle_on > TimeKeeper.date_of_record ? qle_reported_on : qle_on + 30.days
  	notice.qle = PdfTemplates::QualifyingLifeEventKind.new({
  	   :qle_on => qle_on,
  	   :qle_reported_on => qle_reported_on,
  	   :title => title,
  	   :reporting_deadline => reporting_deadline
  	   })
  	active_plan_year = census_employee.employer_profile.plan_years.where(:aasm_state.in => PlanYear::PUBLISHED || PlanYear::RENEWING).first
    renewing_plan_year_start_on = active_plan_year.end_on+1
  	notice.plan_year = PdfTemplates::PlanYear.new({
  	   :open_enrollment_end_on => active_plan_year.open_enrollment_end_on,
  	   :start_on => active_plan_year.start_on,
       :renewing_start_on => renewing_plan_year_start_on
  	   })
  end
end
