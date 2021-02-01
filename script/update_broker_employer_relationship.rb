# frozen_string_literal: true
pdos = SponsoredBenefits::Organizations::PlanDesignOrganization.where(has_active_broker_relationship: false).all

@count = 0
# This was in the original PR but isn't used
# feins = []
pdos.each do |pdo|
  next unless Organization.where(:'employer_profile._id' => pdo.sponsor_profile_id, :'employer_profile.broker_agency_accounts' => {:$elemMatch => { is_active: true, broker_agency_profile_id: pdo.owner_profile_id }}).present?

  pdo.update_attributes(has_active_broker_relationship: true)
  puts "processed broker employer relationship with employer fein: #{pdo.employer_profile.fein} and broker agency profile with fein: #{pdo.broker_agency_profile.organization.fein}"
  @count = @count += 1
end
puts "#{@count} number of pairs been processed"
