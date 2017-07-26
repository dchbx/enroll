require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeNewHireRule < MongoidMigrationTask
  def migrate
    begin
      organizations = Organization.where(fein: ENV['fein'])
      if organizations.size != 1
        raise "check FEIN. Found 0 (or) more than 1 organizations"
      end
      organization = organizations.first
      aasm_state = ENV['plan_year_state'].to_s
      benefit_groups = organization.employer_profile.plan_years.where(aasm_state: aasm_state).first.benefit_groups
      benefit_groups.each do |benefit_group|
        benefit_group.effective_on_kind = "first_of_month" if benefit_group.effective_on_kind == "date_of_hire"
        benefit_group.save!
        puts "Changed New Hire Eligibility rule on plan year for #{organization.legal_name}" unless Rails.env.test?
      end
    rescue => e
      puts "#{e}"
    end
  end
end
