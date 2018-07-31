# enrollment_hbx_ids = [131030,131024,131025,131026,131104,131008,131132]

## This script create to fix the enrollments which are incorrectly linked with external application.
#  We'll query all the enrolments match above criteria and then will associate them with correct application.
#  Below script will also fix benefit group assignments.

sponsorships = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(
  :benefit_applications => {:$elemMatch => { :aasm_state => :imported }}
  )

sponsorships.each do |sponsorship|

  application = sponsorship.benefit_applications.where(:aasm_state => :imported).first
  next if application.blank?

  benefit_package_ids = application.benefit_packages.pluck(:_id)
  families = Family.where(:"households.hbx_enrollments" => {:$elemMatch => {
    :created_at.gt => Date.new(2018,7,11)
    }})

  families.each do |family|
    enrollments = family.active_household.hbx_enrollments.where({
      :sponsored_benefit_package_id.in => benefit_package_ids,
      :created_at.gt => Date.new(2018,7,11)
      })

    enrollments.each do |enrollment|

      valid_application = sponsorship.benefit_applications.where(:aasm_state.in => [:active, :expired]).detect{ |application| 
        application.effective_period.cover?(enrollment.effective_on)
      }

      if valid_application.present?
        begin
          census_employee = enrollment.benefit_group_assignment.census_employee
          benefit_group_assignment = nil

          if census_employee.active_benefit_group_assignment.benefit_application == valid_application
            benefit_group_assignment = census_employee.active_benefit_group_assignment
          end

          if benefit_group_assignment.blank?
            benefit_group_assignment = census_employee.benefit_group_assignments.detect{|assignment| assignment.benefit_application == valid_application}

            if benefit_group_assignment.present? && valid_application.active?
              benefit_group_assignment.update(is_active: true)
            end
          end

          if benefit_group_assignment.blank?
            benefit_group_assignment = census_employee.assign_to_benefit_package(valid_application.benefit_packages.first, valid_application.effective_period.min)
          end

          benefit_package = benefit_group_assignment.benefit_package
          sponsored_benefit = benefit_package.sponsored_benefit_for(enrollment.sponsored_benefit.kind)

          enrollment.update_attributes(
            sponsored_benefit_package_id: benefit_package.id,
            sponsored_benefit_id: sponsored_benefit.id,
            benefit_group_assignment_id: benefit_group_assignment.id)

          puts "Fixed enrollment.....#{enrollment.hbx_id}"
        rescue Exception => e
        end
      end
    end
  end
end