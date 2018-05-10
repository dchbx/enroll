# Run the following - bundle exec rake migrations:generate_notices input_file_name=upload_notice_to_employers
require 'csv'

namespace :migrations do
  desc "Adding notices to ER accounts"
  task :generate_notices => :environment do

    input_file_name = ENV['input_file_name']

    CSV.foreach("#{Rails.root}/lib/#{input_file_name}.csv") do |notice_info|
      fein, file_path, notice_name = notice_info
      ENV['file_path'] = file_path
      ENV['fein'] = fein
      ENV['notice_name'] = notice_name

      begin
        Rake::Task["migrations:upload_notice_to_employer_account"].reenable
        Rake::Task["migrations:upload_notice_to_employer_account"].invoke

        puts "Finished with ER - #{fein}"
      rescue Exception => e
        puts "Errors with #{fein} - #{e}"
      end
    end
  end
end
