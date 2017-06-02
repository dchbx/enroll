# Report: Rake task to generate two reports to find users without gender assigned to person_record users without gender assigned to census employee record
require 'csv'
namespace :report do
  namespace :user_account do
    desc "List of users with no gender assignment to person account and census employee account"
    task :with_no_gender_in_person_or_census_ee_record => :environment do
      users = User.all
      census_ees=CensusEmployee.all
      field_names  = %w(
                         user_first_name
                         user_last_name
                         person_hbx_id
                         has_employer_role(Y/N)
                         has_consumer_role(Y/N)
                         employer_legal_name
                       )
      processed_count = 0
      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/users_account_with_no_gender_in_person_account.csv"
      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        users.each do |user|
          if (user.person.present?)&& (user.person.gender.nil?)
            csv << [user.person.first_name,
                    user.person.last_name,
                    user.person.hbx_id,
                    user.has_employer_staff_role? ? "Y" : "N",
                    user.has_consumer_role? ? "Y" : "N",
                    if user.has_employer_staff_role?
                      staff_id=user.person.employer_staff_roles.first._id
                      EmployerProfile.find(staff_id).nil? ? "Not available" : EmployerProfile.find(staff_id).first.legal_name
                    else
                     "Not available"
                    end
                   ]
            processed_count += 1
          end
        end
        puts "Total users with no gender in person account count #{processed_count} output file: #{file_name}" unless Rails.env == 'test'
      end
      processed_count = 0
      file_name = "#{Rails.root}/hbx_report/users_account_with_no_gender_in_census_ee_account.csv"
      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        census_ees.each do |ce|
          if ce.try(:employee_role).try(:person).try(:user).present?
              person=ce.employee_role.person
              user=ce.employee_role.person.user
              if ce.gender.nil?
                csv << [
                    person.first_name,
                    person.last_name,
                    person.hbx_id,
                    user.has_employer_staff_role? ? "Y" : "N",
                    user.has_consumer_role? ? "Y" : "N",
                    if user.has_employer_staff_role?
                      staff_id=user.person.employer_staff_roles.first._id
                      EmployerProfile.find(staff_id).nil? ? "Not available" : EmployerProfile.find(staff_id).first.legal_name
                    else
                      "Not available"
                    end
                ]
                processed_count += 1
                break
              end
            end
          end
        end
        puts "Total users with no gender in census ee account count #{processed_count} and output file: #{file_name}" unless Rails.env == 'test'
      end
    end
  end






