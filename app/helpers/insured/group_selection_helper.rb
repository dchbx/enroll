module Insured
  module GroupSelectionHelper
    def can_shop_individual?(person)
      person.try(:has_active_consumer_role?)
    end

    def can_shop_shop?(person)
      person.present? && person.has_employer_benefits?
    end

    def can_shop_both_markets?(person)
      can_shop_individual?(person) && can_shop_shop?(person)
    end

    def health_relationship_benefits(employee_role)
      benefit_group = employee_role.census_employee.renewal_published_benefit_group || employee_role.census_employee.active_benefit_group
      if benefit_group.present?
        benefit_group.relationship_benefits.select(&:offered).map(&:relationship)
      end
    end

    def dental_relationship_benefits(employee_role)
      benefit_group = employee_role.census_employee.renewal_published_benefit_group || employee_role.census_employee.active_benefit_group
      if benefit_group.present?
        benefit_group.dental_relationship_benefits.select(&:offered).map(&:relationship)
      end
    end

    def current_user_can_shop_for_ivl?(person)
      if current_user.has_broker_role?
        return the_writing_agent(person) == current_user.person && can_shop_individual?(person)
      else
        return can_shop_individual?(person)
      end
    end

    def the_writing_agent(employee_role_or_person)
      if employee_role_or_person.has_active_employee_role?
        employee_role_or_person.active_employee_roles.first.employer_profile.active_broker_agency_account.writing_agent.person
      elsif employee_role_or_person.has_active_consumer_role?
        employee_role_or_person.primary_family.current_broker_agency.writing_agent.person
      elsif employee_role_or_person.dual_role?
      end
    end

    def current_user_can_shop_for_employee?(person)
      if current_user.has_broker_role?
        return the_writing_agent(person) == current_user.person && can_shop_shop?(person)
      else
        return can_shop_shop?(person)
      end
    end

    def is_eligible_market?(market_kind,person)
      if market_kind == "shop"
        return current_user_can_shop_for_employee?(person)
      else
        return current_user_can_shop_for_ivl?(person)
      end
    end
  end
end
