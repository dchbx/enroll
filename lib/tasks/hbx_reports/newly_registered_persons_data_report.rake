require 'csv'
 # This is a weekly report that pulls the newly enrolled people in that time period.
 # The task to run is RAILS_ENV=production bundle exec rake reports:new_people:total_new_people_list
 namespace :reports do
   namespace :new_people do
 
     desc "List of all new people registered in enroll"
     task :total_new_people_list => :environment do
       include Config::AcaHelper

      end_date = TimeKeeper.date_of_record + 1.day
 
       field_names  = %w(
           FAMILY_ID
           HBX_ID
           Last_Name
           First_Name
           Date_Of_Birth
           SSN
           Relationship
           Application_Date
           Applied_For_Assistance
           Max_APTC
           CSR_percentage
           Is_Medicaid_Chip_Eligible
           Health_Enrollment
           Dental_Enrollment
           Gender
           Home_Phone_Number
           Work_Phone_Number
           Cell_Number
           Home_Email_Address
           Work_Email_Address
           Primary_Applicant_Indicator
           Address_line_1
           Address_line_2
           City
           State
           Zipcode
           Ethnicity
         )
       count = 0
       file_name = fetch_file_format('new_registered_persons_data_report', 'NEWREGISTEREDPERSONSDATA')
 
      CSV.open(file_name, "w", force_quotes: true) do |csv|
         csv << field_names

         families = Family.where(:"created_at" => { "$lt" => end_date})
         families.each do |family|
          primary_fm = family.primary_family_member
          family.family_members.each do |fm|
            begin
              tax_household_member = primary_fm.family.active_household.latest_active_tax_household.tax_household_members.detect {|thm| thm.person.id == fm.person.id } if primary_fm.family.try(:active_household).try(:latest_active_tax_household).try(:tax_household_members).present?
              is_medicaid_chip_eligible = tax_household_member.try(:is_medicaid_chip_eligible).present? ? "Yes" : "No"
              is_applied_for_assistance = primary_fm.family.e_case_id.present? ?  "Yes" : "No"

              enrollments = primary_fm.family.active_household.try(:hbx_enrollments)
              health_enr = enrollments.order_by(:'created_at'.desc).where(:aasm_state.in => HbxEnrollment::ENROLLED_STATUSES, :coverage_kind => "health").first if enrollments.present?
              dental_enr = enrollments.order_by(:'created_at'.desc).where(:aasm_state.in => HbxEnrollment::ENROLLED_STATUSES, :coverage_kind => "dental").first if enrollments.present?
              
              health_enrollment = if health_enr.present? && fm.is_primary_applicant
                                    health_enr.kind == "employer_sponsored" ? "SHOP" : (health_enr.applied_aptc_amount > 0 ? "Assisted QHP" : "UnAssisted QHP")
                                  elsif health_enr.present? && !fm.is_primary_applicant
                                    health_enr.hbx_enrollment_members.detect { |hem| hem.family_member.id == fm.id }.present? ? "Covered Under Primary" : "No Health Enrollment"
                                  else
                                    "No Active Health Enrollment"
                                  end

              dental_enrollment = if dental_enr.present? && fm.is_primary_applicant
                                    dental_enr.kind == "employer_sponsored" ? "SHOP" : (dental_enr.applied_aptc_amount > 0 ? "Assisted QHP" : "UnAssisted QHP")
                                  elsif dental_enr.present? && !fm.is_primary_applicant
                                    dental_enr.hbx_enrollment_members.detect { |hem| hem.family_member.id == fm.id }.present? ? "Covered Under Primary" : "No Dental Enrollment"
                                  else
                                    "No Active Dental Enrollment"
                                  end

              csv << [
                fm.family.hbx_assigned_id,
                fm.hbx_id,
                fm.last_name,
                fm.first_name,
                fm.dob,
                fm.ssn,
                fm.primary_relationship,
                fm.family.created_at,
                is_applied_for_assistance,
                primary_fm.family.try(:active_household).try(:latest_active_tax_household).try(:latest_eligibility_determination).try(:max_aptc),
                primary_fm.family.try(:active_household).try(:latest_active_tax_household).try(:latest_eligibility_determination).try(:csr_percent_as_integer),
                is_medicaid_chip_eligible,
                health_enrollment,
                dental_enrollment,
                fm.gender,
                fm.person.home_phone,
                fm.person.work_phone,
                fm.person.mobile_phone,
                fm.person.home_email.try(:address),
                fm.person.work_email.try(:address),
                fm.is_primary_applicant,
                fm.person.home_address.try(:address_1),
                fm.person.home_address.try(:address_2),
                fm.person.home_address.try(:city),
                fm.person.home_address.try(:state),
                fm.person.home_address.try(:zip),
                fm.person.ethnicity
              ]
              count += 1
            rescue
              puts "Bad family record with id: #{fm.family.id}"
            end
          end
        end
      end

      pubber = Publishers::Legacy::NewPeopleApplicationReportPublisher.new
      pubber.publish URI.join("file://", file_name)

      puts "Total persons created through #{end_date - 1.day} is #{count}"
     end
   end
 end
