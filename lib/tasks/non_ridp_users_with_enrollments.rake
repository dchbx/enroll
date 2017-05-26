# Run the following rake task: RAILS_ENV=production bundle exec rake reports:non_ridp_users_with_enrollments
require 'csv'
namespace :reports do
  desc 'Non-curam Users in a time frame where users can bypass RIDP by changing URL issue present'
  task :non_ridp_users_with_enrollments => :environment do
    start_date = Date.new(2016,1,7)
    end_date = Date.new(2017,2,7)
    count = 0
    size = 0

    field_names  = %w(
      HBX_ID
      FULL_NAME
      SSN
      DOB
      Has_IVL_Enrollment
      Has_SHOP_Enrollment
      Active_Enrollment_Market
    )

    file_name = "#{Rails.root}/public/effected_non_ridp_users_with_enrollments.csv"
    file_name2 = "#{Rails.root}/public/effected_non_ridp_users_without_enrollments.csv"

    def user_having_enrollments?(person)
      if person.primary_family.active_household.present?
        ivl_enr?(person)
      end
    end

    def ivl_enr?(person)
      person.primary_family.active_household.hbx_enrollments.individual_market.present?
    end

    def shop_enr?(person)
      person.primary_family.active_household.hbx_enrollments.shop_market.present?
    end

    def active_enrollment(person)
      person.primary_family.active_household.hbx_enrollments.enrolled.first
    end

    persons = Person.all_consumer_roles.where(:"created_at" => { "$gte" => start_date, "$lte" => end_date}, :user => {:$exists => true})
    
    CSV.open(file_name, "w", force_quotes: true) do |row|
      row << field_names
      persons.each do |person|
        begin
          if !person.user.identity_verified? && person.primary_family.present? && person.primary_family.e_case_id.blank?
            if user_having_enrollments?(person)
              count = count + 1
              invl_enr = ivl_enr?(person)
              shop_enr = shop_enr?(person)
              active_enr = active_enrollment(person)
              row << [
                person.hbx_id,
                person.full_name,
                person.ssn,
                person.dob,
                invl_enr,
                shop_enr,
                active_enr.try(:kind)
              ]
            end
          end
        rescue => e
          puts "check this record: #{person.hbx_id}. Exception: #{e}"
        end
      end
      puts "effected persons with enrollments count: #{count}"
    end

    CSV.open(file_name2, "w", force_quotes: true) do |row|
      row << field_names
      persons.each do |person|
        begin
          if !person.user.identity_verified? && person.primary_family.present? && person.primary_family.e_case_id.blank?
            if !(user_having_enrollments?(person)) && person.consumer_role.bookmark_url.present? && (person.consumer_role.bookmark_url.include? 'home')
              size = size + 1
              invl_enr = ivl_enr?(person)
              shop_enr = shop_enr?(person)
              active_enr = active_enrollment(person)
              row << [
                person.hbx_id,
                person.full_name,
                person.ssn,
                person.dob,
                invl_enr,
                shop_enr,
                active_enr.try(:kind)
              ]
            end
          end
        rescue => e
          puts "check this record: #{person.hbx_id}. Exception: #{e}"
        end
      end
      puts "effected persons without enrollments count: #{size}"
    end
    puts "Total effected persons count: #{count + size }"
  end
end
