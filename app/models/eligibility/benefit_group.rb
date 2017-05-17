module Eligibility
  module BenefitGroup

    def eligible_on(date_of_hire)
      if effective_on_kind == "date_of_hire"
        date_of_hire
      else
        if effective_on_offset == 1
          date_of_hire.end_of_month + 1.day
        else
          if (date_of_hire + effective_on_offset.days).day == 1
            (date_of_hire + effective_on_offset.days)
          else
            (date_of_hire + effective_on_offset.days).end_of_month + 1.day
          end
        end
      end
    end

    def effective_on_for(date_of_hire)
      case effective_on_kind
      when "date_of_hire"
        date_of_hire_effective_on_for(date_of_hire)
      when "first_of_month"
        first_of_month_effective_on_for(date_of_hire)
      end
    end

    def effective_on_for_cobra(date_of_hire)
      case effective_on_kind
      when "date_of_hire"
        [plan_year.start_on, date_of_hire].max
      when "first_of_month"
        [plan_year.start_on, eligible_on(date_of_hire)].max
      end
    end

    def date_of_hire_effective_on_for(date_of_hire)
      [valid_plan_year.start_on, date_of_hire].max
    end

    def first_of_month_effective_on_for(date_of_hire)
      [valid_plan_year.start_on, eligible_on(date_of_hire)].max
    end

    ## Conversion employees are not allowed to buy coverage through off-exchange plan year
    def valid_plan_year    
      if employer_profile.is_conversion?
        plan_year.is_conversion ? plan_year.employer_profile.renewing_plan_year : plan_year
      else
        plan_year
      end
    end
  end
end