require File.join(Rails.root, "lib/mongoid_migration_task")

class FixBenefitGroupAssignmentsForConversionErWithoutActivePlanYear < MongoidMigrationTask
  def migrate
    organizations = Organization.where(:"employer_profile.profile_source" => "conversion", 
                                        :"employer_profile.plan_years.aasm_state".ne => "active",
                                          :"employer_profile.plan_years.is_conversion" => true)
    count = 0

    organizations.each do |organization|
      plan_year = organization.employer_profile.plan_years.order_by(:'start_on'.desc).where(:"aasm_state".in => ["expired", "conversion_expired"], :is_conversion => true).first
      
      if plan_year.present?
        
        census_employees = organization.employer_profile.census_employees.select { |ce| ce.active_benefit_group_assignment.nil? }
        
        census_employees.each do |census_employee|
          begin
            bga = census_employee.benefit_group_assignments.select { |bga| plan_year.benefit_group_ids.include?(bga.benefit_group_id)}.first
            
            if bga.present?
              bga.make_active
              puts "assigned benefit_group for #{census_employee.full_name} of ER: #{organization.legal_name}" unless Rails.env.test?
              count += 1
            else
              bga = BenefitGroupAssignment.new(benefit_group_id: plan_year.benefit_group_ids[0], start_on: plan_year.start_on)

              census_employee.benefit_group_assignments << bga
              census_employee.save!
              puts "New benefit_group_assignment assigned to census_employee #{census_employee.full_name} of ER: #{organization.legal_name}" unless Rails.env.test?
              count += 1
            end
          rescue Exception => e
            puts "#{e}"
          end
        end
      end
    end

    puts "fixed issue for #{count} census employees" unless Rails.env.test?
  end
end
