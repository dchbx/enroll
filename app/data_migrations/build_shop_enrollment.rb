require File.join(Rails.root, "lib/mongoid_migration_task")

class BuildShopEnrollment < MongoidMigrationTask
  def migrate
    begin
      people = Person.where(hbx_id: ENV['person_hbx_id'])
      if people.size !=1 
        puts "Check hbx_id. Found no (or) more than 1 persons" unless Rails.env.test?
        raise
      end
      person = people.first
      effective_on = Date.strptime(ENV['effective_on'].to_s, "%m/%d/%Y")
      plan_year_state = ENV['plan_year_state'].to_s
      new_hbx_id = ENV['new_hbx_id'].to_s
      fein = ENV['fein'].to_s
      hios_id = ENV['hios_id'].to_s
      active_year = ENV['active_year']
      if hios_id.present? && active_year.present?
        plan = Plan.where(hios_id: hios_id, active_year: active_year).first
        if plan.nil?
          puts "This Plan details you entered are incorrect" unless Rails.env.test?
          return
        end
      end
      organizations = Organization.where(fein: fein)
      if organizations.size != 1
        puts "Found More than one (or) no organization with the given FEIN" unless Rails.env.test?
        return
      end

      employer_profile_id = organizations.first.employer_profile.id
      employee_role = person.active_employee_roles.detect { |er| er.employer_profile_id == employer_profile_id}

      benefit_group = organizations.first.employer_profile.plan_years.where(aasm_state: plan_year_state).first.default_benefit_group
      benefit_group ||= organizations.first.employer_profile.plan_years.where(aasm_state: plan_year_state).first.benefit_groups.first
      benefit_group_assignment = employee_role.census_employee.benefit_group_assignments.where(benefit_group_id: benefit_group.id).first
      
      if benefit_group_assignment.nil?
        bga = BenefitGroupAssignment.new(benefit_group: benefit_group, start_on: benefit_group.start_on)
        bga.save!
      end
      
      enrollment = HbxEnrollment.new(kind: "employer_sponsored", enrollment_kind: "open_enrollment", employee_role_id: employee_role.id, benefit_group_id: benefit_group.id, benefit_group_assignment_id: benefit_group_assignment.id)
      enrollment.effective_on = effective_on
      enrollment.plan_id = plan.present? ? plan.id : benefit_group.reference_plan.id
      family_members = person.primary_family.active_family_members.select { |fm| Family::IMMEDIATE_FAMILY.include? fm.primary_relationship }
      family_members.each do |fm|
        hem = HbxEnrollmentMember.new(applicant_id: fm.id, is_subscriber: fm.is_primary_applicant,
                                      eligibility_date: enrollment.effective_on, coverage_start_on: enrollment.effective_on
                                     )
        enrollment.hbx_enrollment_members << hem
        puts "Added coverage for #{fm.person.full_name}" unless Rails.env.test?
      end
      person.primary_family.active_household.hbx_enrollments << enrollment
      person.primary_family.active_household.save!
      enrollment.update_attributes(aasm_state: "coverage_selected")
      if new_hbx_id.present?
        enrollment.update_attributes!(hbx_id: new_hbx_id)
      end
      puts "Created a new shop enrollment with the given effective_on date" unless Rails.env.test?
    rescue => e
      puts "#{e}"
    end
  end
end
