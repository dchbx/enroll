require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateConversionFlag < MongoidMigrationTask
  def migrate
    begin
      feins = ENV['fein'].split(',').map(&:lstrip)
      feins.each do |fein|
      organization = Organization.where(fein: fein)
      if organization.size != 1
        puts "Issues with organization of fein #{fein}" unless Rails.env.test?
        next
      end
        organization.first.employer_profile.update_attributes!(profile_source: ENV['profile_source'])
        puts "Conversion flag updated #{ENV['profile_source']} for #{fein}" unless Rails.env.test?
      end
    rescue
      puts "Bad Employer Record" unless Rails.env.test?
    end
  end
end
