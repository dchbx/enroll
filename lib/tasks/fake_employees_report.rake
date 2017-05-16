require 'csv'

namespace :reports do
  desc "Employees who have potentail fake SSN"
  task :fake_employees => :environment do
    field_names  = %w(
      last_name first_name ssn dob
    )

    people_count =  Person.count
    offset_count = 0
    limit_count = 500
    processed_count = 0
    file_name = "#{Rails.root}/public/potentail_fake_employees_report.csv"

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names

      while (offset_count < people_count) do
        puts "offset_count: #{offset_count}"
        people = Person.limit(limit_count).offset(offset_count).select {|per| potentail_fake_ssn?(per.ssn)}
        people.each do |person|
          csv << [
            person.last_name,
            person.first_name,
            person.ssn,
            person.dob
          ]
          processed_count += 1
        end
        offset_count += limit_count
      end
    end
    puts "find #{processed_count} employees who have potentail fake ssn"
  end

  def potentail_fake_ssn?(ssn)
    return false if ssn.blank?
    #potentail_fake_ssns = %w(12345 000 999 123 98765 012345 987)
    potentail_fake_ssns = %w(000 999 123 98765 012345)
    potentail_fake_ssns.any?{|s| ssn.start_with?(s)}
  end
end
