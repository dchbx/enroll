FEINS= ['943148303', '464579728', '043839260', '900673864', '521689957', '461792659', '521503793', '520971454', '911930832', '311767734', '331003480', '522074374', '522069263', '530198102']

FEINS.each do |fein|
  organizations = Organization.where(fein: fein)

  if organizations.size != 1
    puts "something went wrong with employer: #{fein}"
  else
    organization = organizations.first
    plan_year = organization.employer_profile.plan_years.detect { |py| py.start_on.year == 2017}
  
    if plan_year.present?
      bg_list = plan_year.benefit_groups.map(&:id)
      Family.where(:"households.hbx_enrollments.benefit_group_id".in => bg_list).each do |family|
        enrollments = family.active_household.hbx_enrollments.where(:benefit_group_id.in => bg_list).to_a
        if enrollments.present?
          puts "caneled 2017 enrollments for #{organization.legal_name}"
        end

        enrollments.each do |enrollment|
          enrollment.cancel_coverage! if enrollment.may_cancel_coverage?
        end
      end

      plan_year.update_attributes(aasm_state: 'renewing_canceled')
      puts "moved 2017 plan year state to renewing canceled"
    end

    if organization.employer_profile.is_coversion_employer?
      plan_year = organization.employer_profile.plan_years.detect { |py| py.start_on.year == 2016}
      if plan_year.present? && plan_year.may_conversion_expire?
        plan_year.conversion_expire!
        puts 'moved 2016 plan year state to migration expired'
      end
    end
    organization.employer_profile.revert_application! if organization.employer_profile.may_revert_application?
  end
end
