require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateEmployeePlanSelection < MongoidMigrationTask
  def migrate
    begin
      organization = Organization.where(fein: ENV['fein'].to_s).first
      plan_id = Plan.where(hios_id: ENV['hios_id'], active_year: ENV['active_year']).first.id
      if organization.nil? || plan_id.nil?
        puts "No organization or plan was found by the given information" unless Rails.env.test?
      else
        employer_profile = organization.employer_profile
        if employer_profile.present?
          active_plan_year = employer_profile.active_plan_year
          if active_plan_year.present?
            benefit_groups = active_plan_year.benefit_groups
            if benefit_groups.present?
              bg_list = benefit_groups.map{|a| a.id}
                HbxEnrollment.where(:benefit_group_id.in => bg_list, :plan_id.ne => nil).to_a.each do |enrollment|
                  enrollment.update_attributes(plan_id: plan_id)
                  puts "Changed Plan of Enrollment for #{family.primary_family_member.person.hbx_id}" unless Rails.env.test?
                end
            else
              puts "No benefit groups found with given information" unless Rails.env.test?
            end
          else
            puts "Active plan year is not present employer_profile with fein #{organization.fein}" unless Rails.env.test?
          end
        else
          puts "Employer Profile is not present for organization with fein #{organization.fein}" unless Rails.env.test?
        end
      end
    rescue
      puts e.message
    end
  end
end