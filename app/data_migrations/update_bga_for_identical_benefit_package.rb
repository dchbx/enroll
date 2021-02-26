#frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateBgaForIdenticalBenefitPackage < MongoidMigrationTask

  def migrate
    begin
      title = ENV['title']
      benefit_sponsorship = BenefitSponsors::Organizations::Organization.where(:fein => ENV['fein']).first.active_benefit_sponsorship
      benefit_application = benefit_sponsorship.benefit_applications.where(:"benefit_packages.title" => title).first
      new_benefit_package = benefit_application.benefit_packages.where(title: title).first
      old_benefit_package = benefit_application.benefit_packages.detect { |bp| bp != new_benefit_package }
      census_employees = benefit_sponsorship.profile.census_employees.non_terminated

      if benefit_application.present?
        count = 0
        census_employees.each do |ce|
          if ce.benefit_group_assignments.any?{|a| !a.valid?}
            new_assignment = ce.benefit_group_assignments.where(benefit_package_id: new_benefit_package).first
            if new_assignment.blank?
              ce.benefit_group_assignments.build(benefit_group: new_benefit_package, start_on: new_benefit_package.start_on)
              ce.save(:validate => false)
              count += 1
              puts "New benefit_group_assignment assigned to census_employee #{ce.full_name} of ER: #{benefit_sponsorship.legal_name}" unless Rails.env.test?
            end
          else
            ce.create_benefit_group_assignment([new_benefit_package])
          end
        end


        census_employees.each do |ce|
          invalid_assignment = ce.benefit_group_assignments.detect{|a| !a.valid?}
          next unless invalid_assignment
          new_assignment = ce.active_benefit_group_assignment
          if new_assignment.benefit_package == new_benefit_package
            hbx_enrollment = invalid_assignment.hbx_enrollment
            hbx_enrollment.update(benefit_group_assignment_id: new_assignment.id)
            invalid_assignment.hbx_enrollment_id = nil
          end
          ce.save(:validate => false)
        end


        census_employees.each do |ce|
          old_assignments = ce.benefit_group_assignments.where(:benefit_package_id => old_benefit_package.id)
          new_assignment = ce.active_benefit_group_assignment
          if new_assignment.benefit_package == new_benefit_package
            old_assignments.each do |assignment|
              next if assignment.hbx_enrollment.blank?
              hbx_enrollment =  assignment.hbx_enrollment
              hbx_enrollment.update_attributes({
                                                 sponsored_benefit_package_id: new_benefit_package.id,
                                                 benefit_group_assignment_id: new_assignment.id,
                                                 sponsored_benefit_id: new_benefit_package.sponsored_benefit_for(hbx_enrollment.coverage_kind).id
                                               })
              assignment.hbx_enrollment_id = nil
            end
          end
          ce.save(validate: false)
        end
        puts "fixed issue for #{count} census employees" unless Rails.env.test?
      else
        puts "please provide the correct benefit package title"
      end
    rescue StandardError => e
      puts e.message unless Rails.env.test?
    end
  end
end
