module Aptc
  def get_shopping_tax_household_from_person(person, year)
    if person.present? && person.is_consumer_role_active?
      person.primary_family.latest_household.latest_active_tax_household_with_year(year) rescue nil
    else
      nil
    end
  end
end
