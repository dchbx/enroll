module FinancialAssistance
  module SharedHelper
    def show_component(url)
      if url.split('/')[2] == "consumer_role" || url.split('/')[1] == "insured" && url.split('/')[2] == "interactive_identity_verifications" || url.split('/')[1] == "financial_assistance" && url.split('/')[2] == "applications" || url.split('/')[1] == "insured" && url.split('/')[2] == "family_members" || url.include?("family_relationships")
        false
      else
        true
      end
    end

    def li_nav_classes_for(target)
      current = if controller_name == 'applications'
        if action_name == 'edit'
          :household_info
        else
          :review_and_submit
        end
      elsif controller_name == 'family_members'
        :household_info
      elsif controller_name == 'applicants'
        if action_name == 'step'
          :tax_info
        elsif action_name == 'other_questions'
          :other_questions
        end
      elsif controller_name == 'incomes'
        if action_name == 'other'
          :other_income
        else
          :income
        end
      elsif controller_name == 'deductions'
        :income_adjustments
      elsif controller_name == 'benefits'
        :health_coverage
      elsif controller_name == 'family_relationships'
        :relationships
      end

      order = [:applications, :household_info, :relationships, :income_and_coverage, :tax_info, :income, :other_income, :income_adjustments, :health_coverage, :other_questions, :review_and_submit]

      unless current.blank?
        if target == current
          'activer active'
        elsif order.index(target) < order.index(current)
          'activer'
        else
          ''
        end
      else
        ''
      end
    end

  end
end
