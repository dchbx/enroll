# Report: Rake task to find users account which has oim_id and no email address
# To Run Rake Task: RAILS_ENV=production rake report:user_account:with_no_email_address
require 'csv'

namespace :report do
  namespace :user_account do

    desc "List of users with no email address in user account"
    task :with_no_email_address => :environment do

      persons = User.where(:"oim_id".exists=>true, :"email".exists=>false).map(&:person).compact
      field_names  = %w(
               username
               user_first_name
               user_last_name
               user_roles
               person_hbx_id
               person_home_email
               person_work_email
             )
      processed_count = 0
      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/users_account_with_no_email.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names

        persons.each do |person|
          if person.emails.present?
            csv << [
                person.user.oim_id,
                person.first_name,
                person.last_name,
                person.user.roles,
                person.hbx_id,
                person.try(:emails).where(kind: "home").try(:first).try(:address),
                person.try(:emails).where(kind: "work").try(:first).try(:address)
            ]
            processed_count += 1
          end
        end
        puts "Total users with no email address in user account and with email in person record count #{processed_count} and users account output file: #{file_name}"
      end
    end
  end
end