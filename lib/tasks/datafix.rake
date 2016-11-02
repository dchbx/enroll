namespace :datafix do
  desc "cleanup general agency profiles"
  task general_agency_profile_clean_up: :environment do
  	general_agency_profiles = GeneralAgencyProfile.all
  	general_agency_profiles.each do |ga|
  		ga.general_agency_staff_roles.each do |staff_role|
	  		case staff_role.aasm_state
	  		when 'active'
	  			ga.aasm_state = "is_approved"
	  		when 'denied'
	  			ga.aasm_state = "is_rejected"
	  		when 'decertified'
	  			ga.aasm_state = "is_closed"
	  		end
  			ga.save
  		end
  	end
  end
end
