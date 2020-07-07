# frozen_string_literal: true

require 'csv'
report_field_names = %w[First_Name
                        Last_Name
                        HBX_ID
                        IC_Number
                        Current_APTC_Max
                        New_APTC_Max
                        Current_CSR
                        New_CSR
                        Payload_Determination_Date
                        Current_Eligibility_Determination_Kind
                        New_Eligibility_Determination_Kind
                        Application_Year
                        Current_Plan_Name
                        Current_HIOS_ID
                        Current_Applied_APTC]

logger_field_names = %w[Family_ID Backtrace]

report_file_name = "#{Rails.root}/daily_eligibility_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"
logger_file_name = "#{Rails.root}/daily_eligibility_report_logger_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"
previous_day = Time.now.getlocal.prev_day
start_time = previous_day.beginning_of_day.utc
end_time = previous_day.end_of_day.utc

source_mapper = { 'Renewals' => 'Renewals', 'Admin' =>  'Create Eligibility or Edit Aptc Csr', 'Curam' => 'Curam'}
CSV.open(logger_file_name, 'w', force_quotes: true) do |logger_csv|
  logger_csv << logger_field_names
  CSV.open(report_file_name, 'w', force_quotes: true) do |report_csv|
    report_csv << report_field_names
    families = Family.where(:"households.tax_households.created_at" => { "$gte" => start_time, "$lte" => end_time})
    families.inject(0) do |_dummy, family|
      primary_person = family.primary_person
      e_case_id = family.has_valid_e_case_id? ? family.e_case_id.split('#').last : 'N/A'
      tax_households = family.active_household.tax_households
      thhs_created_yesterday = tax_households.where(:created_at => {"$gte" => start_time, "$lte" => end_time})
      application_years = thhs_created_yesterday.map(&:effective_starting_on).map(&:year).uniq
      active_statuses = %w[coverage_selected auto_renewing renewing_coverage_selected unverified]
      application_years.each do |year|
        active_enrollments = family.hbx_enrollments.by_year(year).individual_market.where(:aasm_state.in => active_statuses, coverage_kind: 'health')
        new_thh = thhs_created_yesterday.tax_household_with_year(year).desc(:created_at).first
        new_ed = new_thh.latest_eligibility_determination
        new_csr_kind = source_mapper[new_ed.source]
        current_thh = tax_households.tax_household_with_year(year).where(:id.ne => new_thh.id).desc(:created_at).first
        current_ed = current_thh&.latest_eligibility_determination
        current_max_aptc = current_ed&.max_aptc&.to_f.present? ? format('%.2f', current_ed.max_aptc.to_f) : 'N/A'
        current_csr_percent = current_ed&.csr_percent_as_integer.present? ? current_ed.csr_percent_as_integer.to_s : 'N/A'
        current_csr_kind = current_ed&.source.present? ? source_mapper[current_ed.source] : 'N/A'

        if active_enrollments.present?
          active_enrollments.each do |enrollment|
            report_csv << [primary_person.first_name, primary_person.last_name,
                           primary_person.hbx_id, e_case_id, current_max_aptc,
                           format('%.2f', new_ed.max_aptc.to_f), current_csr_percent,
                           new_ed.csr_percent_as_integer, new_ed.determined_at,
                           current_csr_kind, new_csr_kind,
                           year, enrollment.product&.title, enrollment.product&.hios_id,
                           enrollment&.applied_aptc_amount]
          end
        else
          report_csv << [primary_person.first_name, primary_person.last_name,
                         primary_person.hbx_id, e_case_id, current_max_aptc,
                         format('%.2f', new_ed.max_aptc.to_f), current_csr_percent,
                         new_ed.csr_percent_as_integer, new_ed.determined_at,
                         current_csr_kind, new_csr_kind,
                         year, 'N/A', 'N/A', 'N/A']
        end
      end
    rescue StandardError => e
      logger_csv << [family.id, e.backtrace[0..5].join('\n')]
    end
  end
end
