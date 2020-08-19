module Aptc
  def get_shopping_tax_households_from_person(person, year)
    if person.present? && person.is_consumer_role_active?
      person.primary_family.latest_household.latest_active_tax_households_with_year(year) rescue nil
    else
      nil
    end
  end

  def get_tax_households_from_family_members(person, family_member_ids, year)
    tax_households = []
    if person.present? && person.has_active_consumer_role?
      family = person.primary_family
      application = family.active_approved_application
      latest_tax_households = family.active_household.latest_active_tax_households_with_year(year)
      if latest_tax_households.present?
        if !latest_tax_households.map(&:application_id).map(&:present?).include?(false)
          application.active_determined_tax_households.each do |th|
            tax_households << th if th.applicants.where(:family_member_id.in => family_member_ids).present?
          end
        else
          latest_tax_households.each do |th|
            tax_households << th if th.tax_household_members.where(:applicant_id.in => family_member_ids).present?
          end
        end
      end
    end
    tax_households.uniq
  end

  def total_aptc_on_tax_households(tax_households, hbx_enrollment)
    total = 0
    tax_households.each do |th|
      total = total + th.total_aptc_available_amount_for_enrollment(hbx_enrollment)
    end
    total
  end
end