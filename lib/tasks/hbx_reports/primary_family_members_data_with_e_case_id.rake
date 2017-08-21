require File.join(Rails.root, "app", "reports", "hbx_reports", "primary_family_members_data_with_e_case_id")
# This will generate a csv file containing primary family members of EA associated with integrated case.
# The task to run is RAILS_ENV=production bundle exec rake reports:primary_family_members:with_e_case_id
namespace :reports do
  namespace :primary_family_members do
    desc "List of all Primary Family Members in Enroll with an associated integrated case"
    PrimaryFamilyMembersDataWithECaseId.define_task  :with_e_case_id => :environment
  end
end
