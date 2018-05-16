#rake profiles_migration site_key=dc profile_type=carrier_profile
#rake profiles_migration site_key=dc profile_type=employer_profile
#rake profiles_migration site_key=dc profile_type=broker_agency_profile

require 'csv'

desc "profiles, its organizations migration"
task :profiles_migration => :environment do
  site_key = ENV['site_key']
  profile_type = ENV['profile_type']

  Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
  file_name = "#{Rails.root}/hbx_report/#{profile_type}_migration_status_#{TimeKeeper.datetime_of_record.strftime("%m_%d_%Y_%H_%M_%S")}.csv"
  field_names = %w( organization_id hbx_id status)

  logger = Logger.new("#{Rails.root}/log/profile_migration_data.log")
  logger.info "Script Start for #{profile_type}_#{TimeKeeper.datetime_of_record}" unless Rails.env.test?

  if site_key.present? && profile_type.present?

    CSV.open(file_name, 'w') do |csv|
      csv << field_names

      #build and create GeneralOrganization and its profiles
      status = ProfilesMigration.create_profile(site_key, profile_type, csv, logger)

      if status
        puts "Rake Task execution completed, check carrier_profile_migration_data logs & carrier_profile_migration_status csv for additional information." unless Rails.env.test?
      else
        logger.info "Check if the inputed ENV values are valid" unless Rails.env.test?
        puts "Rake Task execution failed for given input" unless Rails.env.test?
      end
    end
  else
    puts "Please provide site_key & profile_type" unless Rails.env.test?
  end
  logger.info "End of the script for #{profile_type}" unless Rails.env.test?
end