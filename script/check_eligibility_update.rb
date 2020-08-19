require 'csv'

def check_eligibility_update
  ran = []
  not_run = []
  output_file_name = "#{Rails.root}/eligibility_updated_list_#{DateTime.now.strftime("%m_%d_%Y_%H_%M")}.csv"

  CSV.open(output_file_name, "w") do |output_csv|
    output_csv << ["SSN", "HBX ID", "TAX HOUSEHOLD-submitted_at", "EligibilityDetermination-MAX_APTC", "EligibilityDetermination-CSR", "EligibilityDetermination-E_PDC_ID"]
    CSV.foreach("pids/2018_THHEligibility.csv") do |row_with_ssn|
      ssn, hbx_id, aptc, csr = row_with_ssn
      if ssn && ssn =~ /^\d+$/ && ssn.to_s != '0'
        ssn = '0'*(9-ssn.length) + ssn if ssn.length < 9
        person = Person.by_ssn(ssn).first rescue nil
      end

      unless person
        person = Person.by_hbx_id(hbx_id).first rescue nil
      end

      if person
        unless person.primary_family
          not_run << {no_family: ssn}
          puts "Person with ssn: #{ssn} has no family."
          next
        end
        active_tax_households = person.primary_family.active_household.latest_active_tax_households_with_year(2018)
        deter = active_tax_households.first.try(:latest_eligibility_determination) if active_tax_households.present?
        if deter && deter.e_pdc_id =~ /MANUALLY_10_06_2017LOADING/
          output_csv << [person.ssn, person.hbx_id, deter.tax_household.submitted_at, deter.max_aptc, deter.csr_percent_as_integer, deter.e_pdc_id]
          ran << person.hbx_id
          print 'r'
        end
      else
        not_run << {not_found: ssn}
        puts "Person with ssn: #{ssn} can't be found."
      end
    end
  end

  [ran: {count: ran.count, rs: ran},
   not_run: {count: not_run.count, rs: not_run}]
end