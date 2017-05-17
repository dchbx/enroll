module Employers::PremiumStatementHelper

  def billing_period_dropdown
    select_tag 'billing_date', options_for_select(billing_period_options), {:style => "width: 100px", :id => 'enrollment_report_dropdown'}
  end

  def billing_period_options
    options = []
    
    earliest_effective_plan_date = @employer_profile.earliest_plan_year_start_on_date

    upcoming_billing_date = @employer_profile.billing_plan_year.first.present? ? [TimeKeeper.date_of_record.next_month.beginning_of_month, @employer_profile.billing_plan_year.first.start_on.beginning_of_month].max : TimeKeeper.date_of_record.next_month.beginning_of_month
    if @employer_profile.renewing_plan_year.present?
      renewal_billing_date = @employer_profile.renewing_plan_year.start_on

      3.times do |i|
        billing_date = renewal_billing_date - i.months
        if upcoming_billing_date < billing_date
          options << [billing_date.strftime("%B %Y"), billing_date]
        end
      end
    end

    6.times do |i|
      billing_date = upcoming_billing_date - i.months
      if !earliest_effective_plan_date.nil? && billing_date < earliest_effective_plan_date.beginning_of_month
        break
      end
      options << [billing_date.strftime("%B %Y"), billing_date]
    end

    options
  end
end