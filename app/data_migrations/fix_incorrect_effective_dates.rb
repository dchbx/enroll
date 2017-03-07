class FixIncorrectEffectiveDates < MongoidMigrationTask

  attr_accessor :plan_year_begin

  def migrate
    @plan_year_begin = Date.new(2017,5,1)
    effective_date = (plan_year_begin - 3.months)

    organizations.each do |organization|
      employer_profile = organization.employer_profile
      puts "Processing Employer: #{employer_profile.legal_name}"
      plan_year = employer_profile.plan_years.where(start_on: plan_year_begin.prev_year).first
      id_list = plan_year.benefit_groups.map(&:id)

      families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
      families.inject([]) do |enrollments, family|
        family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).each do |enrollment|
          next if (plan_year.start_on..plan_year.end_on).cover?(enrollment.effective_on)
          if enrollment.benefit_group != enrollment.benefit_group_assignment.benefit_group
            puts "model integrity issue found!!"
            next
          end

          puts "Fixing Enrollment Effective Date for #{family.primary_applicant.person.full_name}"
          enrollment.update(effective_on: effective_date)
        end
      end
    end

    cancel_and_trigger_passive_renewals
  end

  def cancel_and_trigger_passive_renewals
    published_organizations.each do |organization|
      puts "Correcting Passive Renewals for Employer: #{organization.legal_name}"
      renewing_plan_year = organization.employer_profile.renewing_plan_year
      id_list = renewing_plan_year.benefit_groups.map(&:id)

      families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
      families.inject([]) do |enrollments, family|
        family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).each do |enrollment|

          if enrollment.renewing_waived? || enrollment.auto_renewing?
            enrollment.cancel_coverage!
          end
        end
      end

      renewing_plan_year.trigger_passive_renewals
    end
  end

  def organizations
    Organization.where(:"employer_profile.plan_years" => 
      { :$elemMatch => {:start_on => plan_year_begin.prev_year, :aasm_state.in => PlanYear::PUBLISHED}},
      :"employer_profile.profile_source" => 'conversion')
  end

  def published_organizations
    Organization.where(:"employer_profile.plan_years" => 
      { :$elemMatch => {:start_on => plan_year_begin, :aasm_state.in => PlanYear::RENEWING_PUBLISHED_STATE}},
      :"employer_profile.profile_source" => 'conversion')
  end
end