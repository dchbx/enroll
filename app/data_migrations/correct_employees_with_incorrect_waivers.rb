require File.join(Rails.root, "lib/mongoid_migration_task")

class CorrectEmployeesWithIncorrectWaivers < MongoidMigrationTask

  def migrate
    (1..12).each do |i|
      organizations = Organization.exists(:employer_profile => true).where(:'employer_profile.plan_years' => {:$elemMatch => plan_year_query(i)})
      count = 0
      organizations.each do |org|
        plan_year = org.employer_profile.plan_years.where(plan_year_query(i)).first
        next if plan_year.benefit_groups.any?{|bg| bg.is_congress}

        renewal_plan_year = org.employer_profile.plan_years.where(:start_on => plan_year.start_on.next_year).first
        families = Family.where(:'households.hbx_enrollments' => {:$elemMatch => enrollment_query(plan_year)})

        families.each do |f|
          enrollments = f.active_household.hbx_enrollments.where(enrollment_query(plan_year)).sort_by{|e| e.submitted_at || e.created_at }
          next if enrollments.uniq.size < 2

          waiver = enrollments.detect{|e| e.inactive?}
          active_coverage = enrollments.detect{|e| 
            ['coverage_selected', 'coverage_enrolled', 'coverage_expired'].include?(e.aasm_state.to_s)
          }
          if waiver.present? && active_coverage.present?
            next if waiver.created_at.blank? || active_coverage.created_at.blank?
            active_submitted_at = active_coverage.submitted_at || active_coverage.created_at
            waiver_submitted_at = waiver.submitted_at || waiver.created_at

            if active_coverage.created_at > waiver.created_at && waiver_submitted_at > active_submitted_at && active_coverage.effective_on >= waiver.effective_on
              waiver.update(submitted_at: waiver.created_at)
              if waiver.may_cancel_coverage?
                waiver.cancel_coverage!
                person = f.primary_applicant.person
                puts "Canceled 2016 waiver for #{person.full_name}(#{person.hbx_id})" unless Rails.env.test?
              end

              cancel_waiver_and_trigger_renewal(f, renewal_plan_year)
              count += 1
            end
          end
        end
      end
      puts "For #{i} month found #{count}." unless Rails.env.test?
    end
  end

  def cancel_waiver_and_trigger_renewal(family, plan_year)
    bg_ids = plan_year.benefit_groups.pluck(:_id)

    if ['active', 'renewing_enrolling', 'renewing_enrolled'].include?(plan_year.aasm_state.to_s)
      enrollments = family.active_household.hbx_enrollments.where({
        :benefit_group_id.in => bg_ids,
        :coverage_kind => 'health',
        :kind.in => %w(employer_sponsored employer_sponsored_cobra),
        :effective_on => plan_year.start_on,
        :aasm_state.in => ['renewing_waived', 'inactive']
      })

      passives = enrollments.select{|e| e.workflow_state_transitions.where(:to_state => 'renewing_waived').any? }

      if passives.present?
        person = family.primary_applicant.person
        puts "Passively renewed #{person.full_name}(#{person.hbx_id})" unless Rails.env.test?
        passives.each{|e| e.cancel_coverage!}
        ce = passives.first.benefit_group_assignment.census_employee
        renew_health_coverage(plan_year, ce, family)
      end
    end
  end

  def renew_health_coverage(renewing_plan_year, ce, family)
    employer = renewing_plan_year.employer_profile
    active_plan_year = employer.plan_years.where(:start_on => renewing_plan_year.start_on.prev_year, :aasm_state.in => ['active', 'expired']).first

    factory = Factories::FamilyEnrollmentRenewalFactory.new
    factory.family = family
    factory.census_employee = ce
    factory.employer = employer
    factory.renewing_plan_year = renewing_plan_year
    factory.active_plan_year = active_plan_year
    factory.disable_notifications = true
    factory.coverage_kind = 'health'
    factory.generate_renewals
  end

  def plan_year_query(i)
    {
      :start_on => Date.new(ENV['year'],i,1),
      :aasm_state.in => ['active', 'expired']
    }
  end

  def enrollment_query(plan_year)
    bg_ids = plan_year.benefit_groups.pluck(:id)

    {
      :aasm_state.in => ['inactive', 'coverage_selected', 'coverage_enrolled', 'coverage_expired'], 
      :benefit_group_id.in => bg_ids,
      :coverage_kind => 'health',
      :kind.in => %w(employer_sponsored employer_sponsored_cobra)
    }
  end
end
