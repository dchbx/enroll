require 'csv'
 # This is a report of non-enrolled ivl's
 # The task to run is RAILS_ENV=production bundle exec rake reports:non_enrolled_ivls:non_enrolled_ivls
namespace :reports do
  namespace :non_enrolled_ivls do
 
    desc "List of ivl people non enrolled for 2017"
    task :non_enrolled_ivls => :environment do
 
      field_names  = %w(
        PRIMARY_FIRST_NAME
        PRIMARY_LAST_NAME
        PRIMARY_EMAIL
        MOST_RECENT_ENROLLMENT_TERM_DATE
        APPLICATION_CREATED_AT 
      )

      file_name = "#{Rails.root}/public/non_enrolled_ivls_report.csv"
 
      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names

          count = 0
          persons = Person.all_consumer_roles
          persons.each do |person|
            begin
              if person.active_employee_roles.blank? && person.primary_family.try(:active_household).present? && person.primary_family.active_household.hbx_enrollments.by_year(2017).enrolled.blank?
                
                best_email = person.home_email.try(:address) || person.work_email.try(:address) || " No Home (or) Work E-mail"
                enrollment = person.primary_family.active_household.hbx_enrollments.by_year(2017).my_enrolled_plans.first || person.primary_family.active_household.hbx_enrollments.by_year(2016).enrolled.shop_market.first
                term_date = enrollment.present? ? enrollment.terminated_on || enrollment.benefit_group.try(:end_on) : "No IVL (or) active SHOP Enrollment"
                
                csv << [
                  person.first_name,
                  person.last_name,
                  best_email,
                  term_date,
                  person.primary_family.created_at
                ]
                count +=1
              end
            rescue
              puts "bad person record"
            end
          end
        puts "Report generated on persons with Ivl Roles & with NO active employee roles"
        puts "Total non-enrolled ivl's for 2017 are #{count}"
      end
    end
  end
end
