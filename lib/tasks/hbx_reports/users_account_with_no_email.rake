# Report: Rake task to find users account which has oim_id and no email address
# To Run Rake Task: RAILS_ENV=production rake report:user_account:with_no_email_address[start_date,end_date]
# # date_format:RAILS_ENV=production rake report:user_account:with_no_email_address[%d/%m/%Y,%d/%m/%Y]
require 'csv'

namespace :report do
  namespace :user_account do

    desc "List of users with no email address in user account"
    task :with_no_email_address, [:start_date, :end_date] => [:environment] do |task, args|

      start_date = Date.parse(args[:start_date]).beginning_of_day
      end_date = Date.parse(args[:end_date]).end_of_day
      date_range = start_date..end_date

      persons = User.where(:"oim_id".exists=>true, :"email".exists=>false,:"created_at" => date_range).map(&:person).compact
      field_names  = %w(
               username
               user_first_name
               user_last_name
               user_roles
               person_hbx_id
               person_home_email
               person_work_email
               user_created_at
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
                person.try(:emails).where(kind: "work").try(:first).try(:address),
                person.user.created_at
            ]
            processed_count += 1
          end
        end
        puts "Total users with no email address in user account and with email in person record count #{processed_count} and users account output file: #{file_name}" unless Rails.env == 'test'
      end
    end
  end
end
