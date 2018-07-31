Person.all_employer_staff_roles.where(:'employer_staff_roles.benefit_sponsor_employer_profile_id'=> nil, :'employer_staff_roles.employer_profile_id'.exists=> true,:'employer_staff_roles.aasm_state'=> 'is_active').each do |person|
  person.employer_staff_roles.each do |staff|

    if staff.benefit_sponsor_employer_profile_id.blank? && staff.aasm_state == "is_active"

      old_model_fein = EmployerProfile.find(staff.employer_profile_id).fein
      new_org = BenefitSponsors::Organizations::Organization.where(fein: old_model_fein).first

      if new_org.present?
        staff.update_attributes(benefit_sponsor_employer_profile_id: new_org.employer_profile.id)
        puts "Updated staff role details: Staff_aasm_state = #{staff.aasm_state} --- Person_hbx_id = #{staff.person.hbx_id} --- Username = #{staff.person.user.present? ? staff.person.user.email : "no user record"} --- Employer_legal_name = #{staff.profile.legal_name}"
      end

    end
  end
end