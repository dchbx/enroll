# frozen_string_literal: true

module Aptc
  def get_shopping_tax_household_from_person(person, year)
    if person.present? && person.is_consumer_role_active?
      begin
        person.primary_family.latest_household.latest_active_tax_household_with_year(year)
      rescue StandardError
        nil
      end
    end
  end
end
