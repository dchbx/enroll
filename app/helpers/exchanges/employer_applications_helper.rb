module Exchanges
  module EmployerApplicationsHelper

    def can_terminate_application?(plan_year)
      (plan_year.active? || plan_year.expired? || plan_year.suspended?) && plan_year.may_terminate?
    end

    def can_cancel_application?(plan_year)
      if (PlanYear::PUBLISHED + PlanYear::RENEWING + PlanYear::INITIAL_ENROLLING_STATE + ["renewing_application_ineligible", "application_ineligible", "draft"]).include?(plan_year.aasm_state)
        true
      else
        false
      end
    end
  end
end