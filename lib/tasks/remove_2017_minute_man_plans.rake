# the rake task is RAILS_ENV=production bundle exec rake delete:minute_man_plans_2017
namespace :delete do
  desc "remove minuteman organization(& carrier profile) and its plans."
  task :minute_man_plans_2017 => :environment do
    puts "*"*80 unless Rails.env.test?
    puts "Remove minuteman organization" unless Rails.env.test?
    org = Organization.where(fein: 453596033).first
    org.destroy
    puts "successfully removed minuteman organization" unless Rails.env.test?
    puts "Remove minute man 2017 plans" unless Rails.env.test?
    Plan.where(active_year: 2017, carrier_profile_id: "53e67210eb899a4603000053").delete_all
    puts "Successfully removed minute man 2017 plans" unless Rails.env.test?
    puts "*"*80 unless Rails.env.test?
  end
end