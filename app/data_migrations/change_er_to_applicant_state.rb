require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeErToApplicantState < MongoidMigrationTask
  def migrate
    feins=ENV['feins'].split(' ').uniq
    feins.each do |fein|
      organizations = Organization.where(fein: fein)
      next puts "unable to find employer_profile with fein: #{fein}" if organizations.blank?

      if organizations.size > 1
        raise 'more than 1 employer found with given fein'
      end
      
      employer_profile = organizations.first.employer_profile
      plan_year = employer_profile.plan_years.where(aasm_state: ENV['plan_year_state'].to_s).first
      next puts "Present fein: #{fein} is found but it has different plan year assm state" if plan_year.nil?
      employer_profile.revert_application! if employer_profile.may_revert_application?
    end
  end
end
