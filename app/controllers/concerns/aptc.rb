module Aptc
  def get_shopping_tax_household_from_person(person, year)
    if person.present? && person.has_active_consumer_role?
      person.primary_family.active_approved_application.latest_active_tax_households_with_year(year).first rescue nil
    else
      nil
    end
  end

  def get_tax_household_from_family_members(person, family_member_ids)
    tax_households = []
    family_member_ids = family_member_ids.collect { |k,v| v}
    if person.present? && person.has_active_consumer_role?
      application = person.primary_family.active_approved_application
      if application.present?
        application.tax_households.each do |th|
          tax_households << th if th.active_applicants.where(:family_member_id.in => family_member_ids).present?
        end
      end
    end
    tax_households
  end

  def total_aptc_on_tax_households(tax_households, hbx_enrollment)
    total = 0
    tax_households.each do |th|
      total = total + th.total_aptc_available_amount_for_enrollment(hbx_enrollment)
    end
    total
  end
end
