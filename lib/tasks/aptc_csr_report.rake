require 'csv'

namespace :reports do
  desc "APTC/CSR Report from EA"
  task :aptc_csr => :environment do
    field_names  = %w(
          hbx_id
          first_name
          last_name
          dob
          ssn
          16_aptc
          16_csr
          17_aptc
          17_csr
    )
    file_name = "#{Rails.root}/public/aptc_and_csv_report.csv"
    family_count = Family.count
    offset_count = 0
    limit_count = 500
    processed_count = 0

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names

      while (offset_count < family_count) do
        puts "offset_count: #{offset_count}"
        Family.limit(limit_count).offset(offset_count).each do |family|
          person = family.primary_family_member.person rescue nil
          if person.present? && person.consumer_role.present?
            aptc_2016, csr_2016 = get_aptc_and_csr_by_person_and_year(person: person, year: 2016)
            aptc_2017, csr_2017 = get_aptc_and_csr_by_person_and_year(person: person, year: 2017)
            csv << [
              person.hbx_id,
              person.first_name,
              person.last_name,
              person.dob,
              person.ssn,
              aptc_2016,
              csr_2016,
              aptc_2017,
              csr_2017,
            ]
            processed_count += 1
          end
        end
        offset_count += limit_count
      end
    end
    puts "have #{processed_count} person info in reports(#{file_name})"
  end

  def get_aptc_and_csr_by_person_and_year(person: nil, year: 2016)
    tax_household = person.primary_family.latest_household.latest_active_tax_household_with_year(year)
    eligibility_determination = tax_household.latest_eligibility_determination
    [eligibility_determination.max_aptc, eligibility_determination.csr_percent_as_integer]
  rescue => e
    [0, 0]
  end
end
