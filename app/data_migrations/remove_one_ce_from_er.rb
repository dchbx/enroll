require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveOneCeFromEr < MongoidMigrationTask
  def migrate
    fein = ENV['fein']
    ce_id = ENV['ce_id']
    organizations = Organization.where(fein:fein)
    if organizations.size < 1
      puts 'no organization found with given fein #{fein} ' unless Rails.env.test?
      return
    elsif organizations.size > 1
      puts 'more than one organizations were found with given fein #{fein} ' unless Rails.env.test?
      return
    end
    employer_profile = organizations.first.employer_profile
    if employer_profile.nil?
      puts 'no employer profile found with given fein #{fein} ' unless Rails.env.test?
      return
    end
    ce = employer_profile.census_employees.where(id:ce_id).first
    if ce.nil?
      puts 'no ce was found with given fein #{fein}' unless Rails.env.test?
      return
    end
    unless ce.employee_role.nil?
      ce.employee_role.unset(:census_employee_id)
    end
    ce.destroy!
    puts "Deleted the census employee #{ce_id} from the employer roaster" unless Rails.env.test?
  end
end
