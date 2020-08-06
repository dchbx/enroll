# frozen_string_literal: true

class RenewalNotice < Notice

  def initialize(employee, args = {})
    super
    @employee = employee
    @to = "raghuramg83@gmail.com"
    @subject = "Employee Renewal notice"
    @template = "user_mailer/plan_shopping_completed.html.erb"
    build
  end

  def build
    @notice_data = {}
  end
end








