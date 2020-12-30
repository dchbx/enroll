# frozen_string_literal: true

# This report generates a list of people who have csr percent 100 with enrollment and eligibility details.
# rails runner script/report_of_ivl_people_with_csr_percent_100.rb -e production
require 'csv'
field_names = %w[First_Name
                 Last_Name
                 HBX_ID
                 IC_Number
                 Determination_Effective_Date
                 Current_APTC_Max
                 Current_CSR_Percentage
                 Current_CSR_Eligibility_Kind
                 Current_Plan_Name
                 Current_HIOS_ID
                 Current_Applied_APTC]

file_name = "#{Rails.root}/list_of_ivl_people_with_csr_percent_100.csv"

CSV.open(file_name, 'w', force_quotes: true) do |csv|
  csv << field_names
  families = Family.where(:"households.tax_households" => {:$elemMatch => {effective_ending_on: nil, :"eligibility_determinations.csr_percent_as_integer" => 100}})
  families.each do |family|
    primary_person = family.primary_person
    e_case_id = family.has_valid_e_case_id? ? family.e_case_id.split('#').last : 'N/A'
    tax_household = family.active_household.tax_households.where(effective_ending_on: nil, :"eligibility_determinations.csr_percent_as_integer" => 100).min_by(&:effective_starting_on)
    eligibility_determination = tax_household.latest_eligibility_determination
    active_enrollments = family.hbx_enrollments.where(:aasm_state.in => HbxEnrollment::ENROLLED_STATUSES, coverage_kind: 'health')

    if active_enrollments.present?
      active_enrollments.each do |enrollment|
        product = enrollment.product
        csv << [primary_person.first_name, primary_person.last_name, primary_person.hbx_id, e_case_id,
                tax_household.effective_starting_on, eligibility_determination.max_aptc.to_f,
                eligibility_determination.csr_percent_as_integer, eligibility_determination.csr_eligibility_kind,
                product.title, product.hios_id, enrollment.applied_aptc_amount]
      end
    else
      csv << [primary_person.first_name, primary_person.last_name, primary_person.hbx_id, e_case_id,
              tax_household.effective_starting_on, eligibility_determination.max_aptc.to_f,
              eligibility_determination.csr_percent_as_integer, eligibility_determination.csr_eligibility_kind,
              'N/A', 'N/A', 'N/A']
    end
  rescue StandardError => e
    puts "Unable to process family with id: #{family.id}, error: #{e.message}" unless Rails.env.test?
  end
end
