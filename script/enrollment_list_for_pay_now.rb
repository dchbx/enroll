# frozen_string_literal: true

# This script generates a report to list all the Kaiser enrollments
# rails runner script/enrollment_list_for_pay_now.rb -e production
require 'csv'
field_names = %w[First_Name
                 Last_Name
                 HBX_ID
                 Application_Year
                 Enrollment_hbx_id
                 Aasm_state]

file_name = "#{Rails.root}/enrollment_list_for_pay_now.csv"

CSV.open(file_name, 'w', force_quotes: true) do |csv|
  csv << field_names
  effective_on = TimeKeeper.date_of_record
  enrollments = HbxEnrollment.all.where(:kind.in => ['individual', 'coverall'],
                                        :aasm_state.in => ['coverage_selected'],
                                        :effective_on => TimeKeeper.date_of_record,
                                        :product_id.ne => nil,
                                        :coverage_kind.in => ['health'])
  enrollments.each do |enrollment|
    next unless enrollment.product.issuer_profile.legal_name == EnrollRegistry[:pay_now_functionality].setting(:carriers).item
    primary_person = enrollment.family.primary_person
    csv << [primary_person.first_name, primary_person.last_name,
            primary_person.hbx_id, enrollment.effective_on.year,
            enrollment.hbx_id,
            enrollment.aasm_state]
  rescue StandardError => e
    puts "Error: #{e.message}" unless Rails.env.test?
  end
end