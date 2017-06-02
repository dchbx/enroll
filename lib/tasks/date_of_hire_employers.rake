require 'csv'
# This report generates list of all the employers with the new hire eligiblity rule as "date_of_hire" for 2016 plan year.
#RAILS_ENV=production bundle exec rake reports:with_date_of_hire_as_eligibilty_rule:employers
namespace :reports do
  namespace :with_date_of_hire_as_eligibilty_rule do
    desc "All Users"
    task :employers => :environment do

      field_names  = %w(
          legal_name
          plan_year_start_on
          effective_kind
         )


      file_name = "#{Rails.root}/public/employers_with_date_of_hire_rule.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        Organization.all_employer_profiles.each do |organization|
          begin
            organization.employer_profile.plan_years.each do |plan_year|
              if (plan_year.start_on.year == 2016 || plan_year.start_on.year == 2017)
                plan_year.benefit_groups.each do |benefit_group|
                  csv << [ "#{organization.legal_name}", "#{plan_year.start_on}", "#{benefit_group.effective_on_kind}" ] if benefit_group.effective_on_kind == "date_of_hire"
                end
              end
            end
          rescue => e
            puts "Bad Record: #{e}"
          end
        end
        puts "Generates a report of all employers with new hire eligiblity rule as date of hire"
      end
    end
  end
end
