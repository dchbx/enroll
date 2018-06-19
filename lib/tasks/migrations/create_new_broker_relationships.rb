BrokerAgencyProfile.all.each do |broker|
  starting_count = SponsoredBenefits::Organizations::PlanDesignOrganization.count
    employers = []
   broker.employer_clients.each do |client|
      employers << client.legal_name
      SponsoredBenefits::Organizations::BrokerAgencyProfile.assign_employer(broker_agency: broker, employer: client, office_locations: client.parent.office_locations)
   end
   final_count = SponsoredBenefits::Organizations::PlanDesignOrganization.count
   puts "Assigning employers for #{broker.legal_name}"
   puts employers
   puts "Created #{final_count - starting_count} total"
   puts "-------"
end
