module Insured::PlanShopping::ReceiptHelper
  def show_pay_now?
    carrier_with_payment_option? && individual? && initial_enrollment?
  end

  def carrier_with_payment_option?
    @enrollment.plan.carrier_profile.legal_name == "Kaiser"
  end

  def individual?
    @enrollment.kind.in?(['individual', 'coverall'])
  end

  def initial_enrollment?
    #transaction_id created_at effective year
    # can be added when backend part will be done.
    true
  end
end