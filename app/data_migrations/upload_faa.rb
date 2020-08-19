require File.join(Rails.root, "lib/mongoid_migration_task")

class UploadFAA < MongoidMigrationTask
  def migrate
    applications_count = 0
    applicants_count = 0
    incomes_count = 0
    incomes_er_address_count = 0
    incomes_er_phone_count = 0
    benefits_count = 0
    deductions_count = 0


    CSV.foreach("#{Rails.root}/hbx_report/families_with_application.csv", {encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all}) do |application|
      f_id = application.to_hash[:family_id]
      applications_in_draft = Family.find(f_id).application_in_progress
      if !applications_in_draft.present?

      app = Family.find(f_id).applications.create(application.to_hash)
      app.save!
      app.update_attributes(workflow: {"current_step" => 2})
      applications_count = applications_count+1

      #applicants creation
      CSV.foreach("#{Rails.root}/hbx_report/families_with_applicants.csv", {encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all}) do |applicant|
        app_family_member = Family.find(f_id).family_members.where(id: applicant.to_hash[:family_member_id]).first
        app_family_member_id =app_family_member.id.to_s if app_family_member.present?

        if app_family_member_id == applicant.to_hash[:family_member_id]
          applicant = FinancialAssistance::Application.find(app.id).applicants.create(applicant.to_hash)
          applicant.save!
          applicants_count = applicants_count+1
          applicant.update_attributes(workflow: {"current_step" => 1})

          #incomes creation
          CSV.foreach("#{Rails.root}/hbx_report/families_with_applicants_income.csv", {encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all}) do |income|
            if income.present? && app_family_member_id == income.to_hash[:family_member_id]
              new_income = applicant.incomes.create(title: income.to_hash[:title],
                                                    kind: income.to_hash[:kind],
                                                    wage_type: income.to_hash[:wage_type],
                                                    hours_per_week: income.to_hash[:hours_per_week],
                                                    amount: income.to_hash[:amount],
                                                    amount_tax_exempt: income.to_hash[:amount_tax_exempt],
                                                    frequency_kind: income.to_hash[:frequency_kind],
                                                    start_on: income.to_hash[:start_on],
                                                    end_on: income.to_hash[:end_on],
                                                    is_projected: income.to_hash[:is_projected],
                                                    tax_form: income.to_hash[:tax_form],
                                                    employer_name: income.to_hash[:employer_name],
                                                    employer_id: income.to_hash[:employer_id],
                                                    has_property_usage_rights: income.to_hash[:has_property_usage_rights])
              new_income.save!
              incomes_count = incomes_count+1

              #employer address creation
              CSV.foreach("#{Rails.root}/hbx_report/families_with_applicants_income_er_address.csv", {encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all}) do |address|
                if address.present? && app_family_member_id == address.to_hash[:family_member_id] && income.to_hash[:income_id] == address.to_hash[:income_id]
                  new_address = new_income.build_employer_address(
                      kind: address.to_hash[:kind],
                      address_1: address.to_hash[:address_1],
                      address_2: address.to_hash[:address_2],
                      address_3: address.to_hash[:address_3],
                      city: address.to_hash[:city],
                      county: address.to_hash[:county],
                      state: address.to_hash[:state],
                      location_state_code: address.to_hash[:location_state_code],
                      full_text: address.to_hash[:full_text],
                      zip: address.to_hash[:zip],
                      country_name: address.to_hash[:country_name]
                  )
                  new_address.save!
                  incomes_er_address_count=incomes_er_address_count+1
                end
              end

              #employer phone creation
              CSV.foreach("#{Rails.root}/hbx_report/families_with_applicants_income_er_phone.csv", {encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all}) do |phone|
                if phone.present? && app_family_member_id == phone.to_hash[:family_member_id] && income.to_hash[:income_id] == phone.to_hash[:income_id]
                  new_phone = new_income.build_employer_phone(kind: phone.to_hash[:kind],
                                                              country_code: phone.to_hash[:country_code],
                                                              area_code: phone.to_hash[:area_code],
                                                              number: phone.to_hash[:number],
                                                              extension: phone.to_hash[:extension],
                                                              primary: phone.to_hash[:primary],
                                                              full_phone_number: phone.to_hash[:full_phone_number])
                  new_phone.save!
                  incomes_er_phone_count=incomes_er_phone_count+1
                end
              end
            end
          end

          #benefit creation
          CSV.foreach("#{Rails.root}/hbx_report/families_with_applicants_benefit.csv", {encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all}) do |benefit|
            if benefit.present? && app_family_member_id == benefit.to_hash[:family_member_id]
              new_benefit = applicant.benefits.create(title: benefit.to_hash[:title],
                                        esi_covered: benefit.to_hash[:esi_covered],
                                        kind: benefit.to_hash[:kind],
                                        insurance_kind: benefit.to_hash[:insurance_kind],
                                        is_employer_sponsored: benefit.to_hash[:is_employer_sponsored],
                                        is_esi_waiting_period: benefit.to_hash[:is_esi_waiting_period],
                                        is_esi_mec_met: benefit.to_hash[:is_esi_mec_met],
                                        employee_cost: benefit.to_hash[:employee_cost],
                                        employee_cost_frequency: benefit.to_hash[:employee_cost_frequency],
                                        start_on: benefit.to_hash[:start_on],
                                        end_on: benefit.to_hash[:end_on],
                                        employer_name: benefit.to_hash[:employer_name])
              new_benefit.save!
              benefits_count = benefits_count+1
            end
          end

          #deduction creation
          CSV.foreach("#{Rails.root}/hbx_report/families_with_applicants_deduction.csv", {encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all}) do |deduction|
            if deduction.present? && app_family_member_id == deduction.to_hash[:family_member_id]
              new_deductions = applicant.deductions.create(title: deduction.to_hash[:title],
                                          kind: deduction.to_hash[:kind],
                                          amount: deduction.to_hash[:amount],
                                          start_on: deduction.to_hash[:start_on],
                                          end_on: deduction.to_hash[:end_on],
                                          frequency_kind: deduction.to_hash[:frequency_kind])
              new_deductions.save!
              deductions_count= deductions_count+1
            end
          end #deductions csv ended

        end
      end #applicants csv ended
      application_in_draft = Family.find(f_id).latest_drafted_application
      application_in_draft.sync_family_members_with_applicants
      else
        puts "Family with id:#{f_id} already have application in draft state}"
      end
    end
    puts "----uploaded from CSV to Enroll app: FAA----"
    puts "applications created #{applications_count}"
    puts "applicants created #{applicants_count}"
    puts "incomes created #{incomes_count}"
    puts "employer addresses created #{incomes_er_address_count}"
    puts "employer phones created #{incomes_er_phone_count }"
    puts "benefits created #{benefits_count}"
    puts "deductions created #{deductions_count}"
  end
end