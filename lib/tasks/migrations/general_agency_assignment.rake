require File.join(Rails.root, "app", "data_migrations", "general_agency_assignment")
# This rake task is to assign the general agecncy assignment for a employer of broker agency

# RAILS_ENV=production bundle exec rake migrations:general_agency_assignment general_agency_id='5733519a50526c236e00001f' employer_profile_id='579ea230faca143fe5000d3c' broker_agency_id='561bf2ee547265b236610400' open_enrollment_end_on='10/13/2016' aasm_state='active'

# RAILS_ENV=production bundle exec rake migrations:general_agency_assignment general_agency_id='5733519a50526c236e00001f' employer_profile_id='579ea233faca143fe5000e5c' broker_agency_id='561bf2ee547265b236610400' open_enrollment_end_on='10/13/2016' aasm_state='active'

namespace :migrations do
  desc "assign the general agecncy assignment for a employer of broker agency"
  GeneralAgencyAssignment.define_task :general_agency_assignment => :environment
end
