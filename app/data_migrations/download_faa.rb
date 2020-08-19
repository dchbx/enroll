require File.join(Rails.root, "lib/mongoid_migration_task")

class DownloadFAA < MongoidMigrationTask
  def migrate
    application_ids = ENV['application_ids'].to_s # Application IDs which need to be downloaded are passed here.
    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    file_name = "#{Rails.root}/hbx_report/families_with_application.csv"
    file_name_applicants = "#{Rails.root}/hbx_report/families_with_applicants.csv"
    file_name_applicants_income = "#{Rails.root}/hbx_report/families_with_applicants_income.csv"
    file_name_applicants_income_er_address = "#{Rails.root}/hbx_report/families_with_applicants_income_er_address.csv"
    file_name_applicants_income_er_phone = "#{Rails.root}/hbx_report/families_with_applicants_income_er_phone.csv"
    file_name_applicants_benefit = "#{Rails.root}/hbx_report/families_with_applicants_benefit.csv"
    file_name_applicants_deduction = "#{Rails.root}/hbx_report/families_with_applicants_deduction.csv"

    applications_count = 0
    applicants_count = 0
    incomes_count = 0
    incomes_er_address_count = 0
    incomes_er_phone_count = 0
    benefits_count = 0
    deductions_count = 0

    application_field_names = %w(
                                 family_id
                                 external_id
                                 integrated_case_id
                                 applicant_kind
                                 request_kind
                                 motivation_kind
                                 is_joint_tax_filing
                                 aasm_state
                                 is_renewal_authorized
                                 renewal_base_year
                                 years_to_renew
                                 is_requesting_voter_registration_application_in_mail
                                 us_state
                                 medicaid_terms
                                 medicaid_insurance_collection_terms
                                 report_change_terms
                                 parent_living_out_of_home_terms
                                 attestation_terms
                                 submission_terms
                                 request_full_determination
                                 is_ridp_verified
                                 has_eligibility_response
                                 )

    applicants_field_names = %w(
                               assisted_income_validation
                               assisted_mec_validation
                               assisted_income_reason
                               assisted_mec_reason
                               aasm_state
                               family_member_id
                               is_active
                               has_fixed_address
                               is_living_in_state
                               is_temp_out_of_state
                               is_required_to_file_taxes
                               tax_filer_kind
                               is_joint_tax_filing
                               is_claimed_as_tax_dependent
                               claimed_as_tax_dependent_by
                               is_ia_eligible
                               is_medicaid_chip_eligible
                               is_non_magi_medicaid_eligible
                               is_totally_ineligible
                               is_without_assistance
                               has_income_verification_response
                               has_mec_verification_response
                               magi_medicaid_monthly_household_income
                               magi_medicaid_monthly_income_limit
                               magi_as_percentage_of_fpl
                               magi_medicaid_type
                               magi_medicaid_category
                               medicaid_household_size
                               is_magi_medicaid
                               is_medicare_eligible
                               is_student
                               student_kind
                               student_school_kind
                               student_status_end_on
                               is_self_attested_blind
                               is_self_attested_disabled
                               is_self_attested_long_term_care
                               is_veteran
                               is_refugee
                               is_trafficking_victim
                               is_former_foster_care
                               age_left_foster_care
                               foster_care_us_state
                               had_medicaid_during_foster_care
                               is_pregnant
                               is_enrolled_on_medicaid
                               is_post_partum_period
                               children_expected_count
                               pregnancy_due_on
                               pregnancy_end_on
                               is_subject_to_five_year_bar
                               is_five_year_bar_met
                               is_forty_quarters
                               is_ssn_applied
                               non_ssn_apply_reason
                               moved_on_or_after_welfare_reformed_law
                               is_veteran_or_active_military
                               is_spouse_or_dep_child_of_veteran_or_active_military
                               is_currently_enrolled_in_health_plan
                               has_daily_living_help
                               need_help_paying_bills
                               is_resident_post_092296
                               is_vets_spouse_or_child
                               has_job_income
                               has_self_employment_income
                               has_other_income
                               has_deductions
                               has_enrolled_health_coverage
                               has_eligible_health_coverage
                               )

    applicants_field_names_income = %w(
                                        family_member_id
                                        income_id
                                        title
                                        kind
                                        wage_type
                                        hours_per_week
                                        amount
                                        amount_tax_exempt
                                        frequency_kind
                                        start_on
                                        end_on
                                        is_projected
                                        tax_form
                                        employer_name
                                        employer_id
                                        has_property_usage_rights
                                        )

    applicants_field_names_benefit = %w(
                                        family_member_id
                                        title
                                        esi_covered
                                        kind
                                        insurance_kind
                                        is_employer_sponsored
                                        is_esi_waiting_period
                                        is_esi_mec_met
                                        employee_cost
                                        employee_cost_frequency
                                        start_on
                                        end_on
                                        employer_name
                                        employer_id
                                        )

    applicants_field_names_deduction = %w(
                                          family_member_id
                                          title
                                          kind
                                          amount
                                          start_on
                                          end_on
                                          frequency_kind
                                          )

    applicants_field_names_income_employer_address = %w(
                                          family_member_id
                                           income_id
                                           kind
                                           address_1
                                           address_2
                                           address_3
                                           city
                                           county
                                           state
                                           location_state_code
                                           full_text
                                           zip
                                           country_name
                                          )

    applicants_field_names_income_employer_phone = %w(
                                          family_member_id
                                           income_id
                                           kind
                                           country_code
                                           area_code
                                           number
                                           extension
                                           primary
                                           full_phone_number
                                          )

    CSV.open(file_name, "wb") do |application_csv|
      application_csv << application_field_names
      CSV.open(file_name_applicants, "wb") do |applicant_csv|
        applicant_csv << applicants_field_names
        CSV.open(file_name_applicants_income, "wb") do |income_csv|
          income_csv << applicants_field_names_income
          CSV.open(file_name_applicants_income_er_address, "wb") do |income_employer_address_csv|
            income_employer_address_csv << applicants_field_names_income_employer_address
            CSV.open(file_name_applicants_income_er_phone, "wb") do |income_employer_phone_csv|
              income_employer_phone_csv << applicants_field_names_income_employer_phone
              CSV.open(file_name_applicants_benefit, "wb") do |benefit_csv|
                benefit_csv << applicants_field_names_benefit
                CSV.open(file_name_applicants_deduction, "wb") do |deduction_csv|
                  deduction_csv << applicants_field_names_deduction

                  core_29_app_ids = application_ids.split(',')
                  core_29_applications = FinancialAssistance::Application.where(id: {:$in => core_29_app_ids})
                  core_29_applications.each do |application|
                    applicants = application.applicants

                    application_csv << [
                        application.family_id,
                        application.external_id.nil? ? "nil" : application.external_id,
                        application.integrated_case_id.nil? ? "nil" : application.integrated_case_id,
                        application.applicant_kind.nil? ? "nil" : application.applicant_kind,
                        application.request_kind.nil? ? "nil" : application.request_kind,
                        application.motivation_kind.nil? ? "nil" : application.motivation_kind,
                        application.is_joint_tax_filing.nil? ? "nil" : application.is_joint_tax_filing,
                        "draft",
                        application.is_renewal_authorized.nil? ? "nil" : application.is_renewal_authorized,
                        application.renewal_base_year,
                        application.years_to_renew,
                        application.is_requesting_voter_registration_application_in_mail.nil? ? "nil" : application.is_requesting_voter_registration_application_in_mail,
                        application.us_state.nil? ? "nil" : application.us_state,
                        application.medicaid_terms.nil? ? "nil" : application.medicaid_terms,
                        application.medicaid_insurance_collection_terms.nil? ? "nil" : application.medicaid_insurance_collection_terms,
                        application.report_change_terms.nil? ? "nil" : application.report_change_terms,
                        application.parent_living_out_of_home_terms.nil? ? "nil" : application.parent_living_out_of_home_terms,
                        application.attestation_terms.nil? ? "nil" : application.attestation_terms,
                        application.submission_terms.nil? ? "nil" : application.submission_terms,
                        application.request_full_determination.nil? ? "nil" : application.request_full_determination,
                        application.is_ridp_verified.nil? ? "nil" : application.is_ridp_verified,
                        application.has_eligibility_response.nil? ? "nil" : application.has_eligibility_response
                    ]
                    applications_count=applications_count+1

                    applicants.each do |applicant|
                      applicant_csv << [
                          applicant.assisted_income_validation.nil? ? "nil" : applicant.assisted_income_validation,
                          applicant.assisted_mec_validation.nil? ? "nil" : applicant.assisted_mec_validation,
                          applicant.assisted_income_reason.nil? ? "nil" : applicant.assisted_income_reason,
                          applicant.assisted_mec_reason.nil? ? "nil" : applicant.assisted_mec_reason,
                          applicant.aasm_state.nil? ? "nil" : applicant.aasm_state,
                          applicant.family_member_id.nil? ? "nil" : applicant.family_member_id,
                          applicant.is_active.nil? ? "nil" : applicant.is_active,
                          applicant.has_fixed_address.nil? ? "nil" : applicant.has_fixed_address,
                          applicant.is_living_in_state.nil? ? "nil" : applicant.is_living_in_state,
                          applicant.is_temp_out_of_state.nil? ? "nil" : applicant.is_temp_out_of_state,
                          applicant.is_required_to_file_taxes.nil? ? "nil" : applicant.is_required_to_file_taxes,
                          applicant.tax_filer_kind.nil? ? "nil" : applicant.tax_filer_kind,
                          applicant.is_joint_tax_filing.nil? ? "nil" : applicant.is_joint_tax_filing,
                          applicant.is_claimed_as_tax_dependent.nil? ? "nil" : applicant.is_claimed_as_tax_dependent,
                          applicant.claimed_as_tax_dependent_by.nil? ? "nil" : applicant.claimed_as_tax_dependent_by,
                          applicant.is_ia_eligible.nil? ? "nil" : applicant.is_ia_eligible,
                          applicant.is_medicaid_chip_eligible.nil? ? "nil" : applicant.is_medicaid_chip_eligible,
                          applicant.is_non_magi_medicaid_eligible.nil? ? "nil" : applicant.is_non_magi_medicaid_eligible,
                          applicant.is_totally_ineligible.nil? ? "nil" : applicant.is_totally_ineligible,
                          applicant.is_without_assistance.nil? ? "nil" : applicant.is_without_assistance,
                          applicant.has_income_verification_response.nil? ? "nil" : applicant.has_income_verification_response,
                          applicant.has_mec_verification_response.nil? ? "nil" : applicant.has_mec_verification_response,
                          applicant.magi_medicaid_monthly_household_income.nil? ? "nil" : applicant.magi_medicaid_monthly_household_income,
                          applicant.magi_medicaid_monthly_income_limit.nil? ? "nil" : applicant.magi_medicaid_monthly_income_limit,
                          applicant.magi_as_percentage_of_fpl.nil? ? "nil" : applicant.magi_as_percentage_of_fpl,
                          applicant.magi_medicaid_type.nil? ? "nil" : applicant.magi_medicaid_type,
                          applicant.magi_medicaid_category.nil? ? "nil" : applicant.magi_medicaid_category,
                          applicant.medicaid_household_size.nil? ? "nil" : applicant.medicaid_household_size,
                          applicant.is_magi_medicaid.nil? ? "nil" : applicant.is_magi_medicaid,
                          applicant.is_medicare_eligible.nil? ? "nil" : applicant.is_medicare_eligible,
                          applicant.is_student.nil? ? "nil" : applicant.is_student,
                          applicant.student_kind.nil? ? "nil" : applicant.student_kind,
                          applicant.student_school_kind.nil? ? "nil" : applicant.student_school_kind,
                          applicant.student_status_end_on.nil? ? "nil" : applicant.student_status_end_on,
                          applicant.is_self_attested_blind.nil? ? "nil" : applicant.is_self_attested_blind,
                          applicant.is_self_attested_disabled.nil? ? "nil" : applicant.is_self_attested_disabled,
                          applicant.is_self_attested_long_term_care.nil? ? "nil" : applicant.is_self_attested_long_term_care,
                          applicant.is_veteran.nil? ? "nil" : applicant.is_veteran,
                          applicant.is_refugee.nil? ? "nil" : applicant.is_refugee,
                          applicant.is_trafficking_victim.nil? ? "nil" : applicant.is_trafficking_victim,
                          applicant.is_former_foster_care.nil? ? "nil" : applicant.is_former_foster_care,
                          applicant.age_left_foster_care.nil? ? "nil" : applicant.age_left_foster_care,
                          applicant.foster_care_us_state.nil? ? "nil" : applicant.foster_care_us_state,
                          applicant.had_medicaid_during_foster_care.nil? ? "nil" : applicant.had_medicaid_during_foster_care,
                          applicant.is_pregnant.nil? ? "nil" : applicant.is_pregnant,
                          applicant.is_enrolled_on_medicaid.nil? ? "nil" : applicant.is_enrolled_on_medicaid,
                          applicant.is_post_partum_period.nil? ? "nil" : applicant.is_post_partum_period,
                          applicant.children_expected_count.nil? ? "nil" : applicant.children_expected_count,
                          applicant.pregnancy_due_on.nil? ? "nil" : applicant.pregnancy_due_on,
                          applicant.pregnancy_end_on.nil? ? "nil" : applicant.pregnancy_end_on,
                          applicant.is_subject_to_five_year_bar.nil? ? "nil" : applicant.is_subject_to_five_year_bar,
                          applicant.is_five_year_bar_met.nil? ? "nil" : applicant.is_five_year_bar_met,
                          applicant.is_forty_quarters.nil? ? "nil" : applicant.is_forty_quarters,
                          applicant.is_ssn_applied.nil? ? "nil" : applicant.is_ssn_applied,
                          applicant.non_ssn_apply_reason.nil? ? "nil" : applicant.non_ssn_apply_reason,
                          applicant.moved_on_or_after_welfare_reformed_law.nil? ? "nil" : applicant.moved_on_or_after_welfare_reformed_law,
                          applicant.is_veteran_or_active_military.nil? ? "nil" : applicant.is_veteran_or_active_military,
                          applicant.is_spouse_or_dep_child_of_veteran_or_active_military.nil? ? "nil" : applicant.is_spouse_or_dep_child_of_veteran_or_active_military,
                          applicant.is_currently_enrolled_in_health_plan.nil? ? "nil" : applicant.is_currently_enrolled_in_health_plan,
                          applicant.has_daily_living_help.nil? ? "nil" : applicant.has_daily_living_help,
                          applicant.need_help_paying_bills.nil? ? "nil" : applicant.need_help_paying_bills,
                          applicant.is_resident_post_092296.nil? ? "nil" : applicant.is_resident_post_092296,
                          applicant.is_vets_spouse_or_child.nil? ? "nil" : applicant.is_vets_spouse_or_child,
                          applicant.has_job_income.nil? ? "nil" : applicant.has_job_income,
                          applicant.has_self_employment_income.nil? ? "nil" : applicant.has_self_employment_income,
                          applicant.has_other_income.nil? ? "nil" : applicant.has_other_income,
                          applicant.has_deductions.nil? ? "nil" : applicant.has_deductions,
                          applicant.has_enrolled_health_coverage.nil? ? "nil" : applicant.has_enrolled_health_coverage,
                          applicant.has_eligible_health_coverage.nil? ? "nil" : applicant.has_eligible_health_coverage
                      ]
                      applicants_count=applicants_count+1

                      applicant.incomes.each do |i|
                        income_csv <<[
                            applicant.family_member_id,
                            i.id,
                            i.title,
                            i.kind,
                            i.wage_type,
                            i.hours_per_week,
                            i.amount,
                            i.amount_tax_exempt,
                            i.frequency_kind,
                            i.start_on,
                            i.end_on,
                            i.is_projected,
                            i.tax_form,
                            i.employer_name,
                            i.employer_id,
                            i.has_property_usage_rights
                        ]
                        incomes_count=incomes_count+1

                        if i.employer_address.present?

                          income_employer_address_csv <<[applicant.family_member_id,
                                                         i.id,
                                                         i.employer_address.kind,
                                                         i.employer_address.address_1,
                                                         i.employer_address.address_2,
                                                         i.employer_address.address_3,
                                                         i.employer_address.city,
                                                         i.employer_address.county,
                                                         i.employer_address.state,
                                                         i.employer_address.location_state_code,
                                                         i.employer_address.full_text,
                                                         i.employer_address.zip,
                                                         i.employer_address.country_name
                          ]
                          incomes_er_address_count=incomes_er_address_count+1


                          income_employer_phone_csv <<[applicant.family_member_id,
                                                       i.id,
                                                       i.employer_phone.kind,
                                                       i.employer_phone.country_code,
                                                       i.employer_phone.area_code,
                                                       i.employer_phone.number,
                                                       i.employer_phone.extension,
                                                       i.employer_phone.primary,
                                                       i.employer_phone.full_phone_number
                          ]
                          incomes_er_phone_count=incomes_er_phone_count+1

                        end
                      end

                      applicant.benefits.each do |i|
                        benefit_csv <<[applicant.family_member_id,
                                       i.title,
                                       i.esi_covered,
                                       i.kind,
                                       i.insurance_kind,
                                       i.is_employer_sponsored,
                                       i.is_esi_waiting_period,
                                       i.is_esi_mec_met,
                                       i.employee_cost,
                                       i.employee_cost_frequency,
                                       i.start_on,
                                       i.end_on,
                                       i.employer_name,
                                       i.employer_id
                        ]
                        benefits_count=benefits_count+1
                      end

                      applicant.deductions.each do |i|
                        deduction_csv <<[applicant.family_member_id,
                                         i.title,
                                         i.kind,
                                         i.amount,
                                         i.start_on,
                                         i.end_on,
                                         i.frequency_kind
                        ]
                        deductions_count=deductions_count+1
                      end
                    end
                  end #Application.each iteration
                  #end #data_hash end
                end #close deduction_csv
              end
            end
          end
        end

      end
    end
    puts "----loaded to CSV from Enroll app: FAA----"
    puts "applications downloaded #{applications_count}"
    puts "applicants downloaded #{applicants_count}"
    puts "incomes downloaded #{incomes_count}"
    puts "employer addresses downloaded #{incomes_er_address_count}"
    puts "employer phones downloaded #{incomes_er_phone_count }"
    puts "benefits downloaded #{benefits_count}"
    puts "deductions downloaded #{deductions_count}"
  end
end