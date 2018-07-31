def profile_fein_for_role(role)
  old_profile_id = role.employer_profile_id.to_s
  ::EmployerProfile.find(old_profile_id).try(:fein)
end

feins = [ "050518534", "030588648", "041617630", "041810570", "042967119", "043399205",
          "454250584", "261371614", "263318062", "264614399", "452470242", "462500520",
          "471059736", "472616958", "043123620", "204510718", "204205722", "043539297",
          "237188764", "463784440", "043006020", "270048494", "463331451", "270048494",
          "813641834", "571153625", "204205722", "043076600"
        ]

people = Person.all_employer_staff_roles.where(:"employer_staff_roles" =>
  { 
    :"$elemMatch" => {
      :"benefit_sponsor_employer_profile_id" => nil,
      :"created_at".gte => Date.new(2018, 7, 12)
    }
  }
)

people.each do |person|
  person.employer_staff_roles.where(
    :"benefit_sponsor_employer_profile_id" => nil,
    :"created_at".gte => Date.new(2018, 7, 12)
  ).each do |role|
    fein = profile_fein_for_role(role)
    if fein.present? && feins.include?(fein)
      organizations = BenefitSponsors::Organizations::Organization.where(fein: fein)
      if organizations.size != 1
        puts "Found No/More than 1 Organization for #{person.full_name}"
        next
      end

      profile_id = organizations.first.employer_profile.id
      if role.update_attributes(benefit_sponsor_employer_profile_id: profile_id)
        puts "Successfully updated ER staff role on #{person.full_name} for employer with fein #{fein} & user_name#{person.try(:user).try(:email)}"
      else
        puts "Staff Role update failed for #{person.full_name} for employer with fein #{fein}"
      end
    else
      puts "Fein Not included in the list, employer with this fein #{fein} not fixed in the script need to check and verify employer staff role"
    end
  end
end
