# This rake task is to generate families report
# RAILS_ENV=production bundle exec rake generate_report:families

namespace :generate_report do
  desc "families with inactive tax household for current year and active tax_households for next year"

  task :families => :environment do
    current_year = ENV['tax_household_year'].to_i
    next_year = current_year + 1
    field_names = %w(
          hbx_id
          first_name
          last_name
          ssn
          2018_max_aptc
          2018_csr
          2018_thh_effective_start_date
          2018_thh_effective_end_date
          2018_e_pdc_id
          2018_created_source
          2019_thh_effective_start_date
          2019_thh_effective_end_date
          2019_e_pdc_id
          2019_created_source
        )

    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    file_name = "#{Rails.root}/hbx_report/families_with_inactive_tax_household_#{Time.now.strftime('%Y%m%d%H%M')}.csv"

    CSV.open(file_name, "w") do |csv|
      csv << field_names
      Family.all_tax_households.where(:"households.tax_households.effective_starting_on" => (Date.new(next_year)..Date.new(next_year).end_of_year)).each do |f|

        tax_households = f.active_household.tax_households
        primary_person = f.primary_family_member.person

        thh_2019 = tax_households.tax_household_with_year(next_year).active_tax_household.order_by(:'created_at'.desc).first

        next unless thh_2019.present?

        thhs_2018 = tax_households.tax_household_with_year(current_year)
        thh_2018 = thhs_2018.order_by(:'created_at'.desc).first
        next unless thhs_2018.present?

        active_thh_2018 = thhs_2018.active_tax_household

        if active_thh_2018.count == 0 && thh_2018.effective_ending_on == thh_2019.effective_starting_on

          csv << [
              primary_person.hbx_id,
              primary_person.first_name,
              primary_person.last_name,
              primary_person.ssn,
              thh_2018.eligibility_determinations.first.max_aptc.to_f,
              thh_2018.eligibility_determinations.first.csr_percent_as_integer,
              thh_2018.effective_starting_on,
              thh_2018.effective_ending_on,
              thh_2018.eligibility_determinations.first.e_pdc_id,
              thh_2018.eligibility_determinations.first.source,
              thh_2019.effective_starting_on,
              thh_2019.effective_ending_on,
              thh_2019.eligibility_determinations.first.e_pdc_id,
              thh_2019.eligibility_determinations.first.source
          ]

        end
      end
    end
  end
end