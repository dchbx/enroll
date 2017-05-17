module Factories
  class EmployerOpenEnrollmentFactory

    attr_accessor :employer_profile, :date, :renewing_plan_year

    def initialize
      @logger = Logger.new("#{Rails.root}/log/employer_open_enrollment_factory_logfile.log")
    end

    def begin_open_enrollment
      @logger.debug "Starting open enrollment for #{employer_profile.legal_name}"
      plan_years_for_oe = employer_profile.plan_years.published_or_renewing_published.where(:"open_enrollment_end_on".gte => @date)

      if plan_years_for_oe.size > 1
        @logger.debug "Error: found more than one published plan year for #{employer_profile.legal_name}"
        return
      end

      published_plan_year = plan_years_for_oe.first
      if published_plan_year && published_plan_year.may_advance_date?
        published_plan_year.advance_date!
      end
    end

    def end_open_enrollment
      @logger.debug "Ending open enrollment for #{employer_profile.legal_name}"
      plan_years_for_oe = employer_profile.plan_years.published_or_renewing_published.select do |py|
        py.open_enrollment_end_on < @date && py.start_on > @date
      end

      if plan_years_for_oe.size > 1
        @logger.debug "Error: found more than one published plan year for #{employer_profile.legal_name}"
        return
      end

      published_plan_year = plan_years_for_oe.first
      published_plan_year.advance_date! if published_plan_year && published_plan_year.may_advance_date?
    end

    def process_family_enrollment_renewals
      @logger.debug "Processing enrollment renewals for #{employer_profile.legal_name}"

      default_benefit_group = @employer_profile.default_benefit_group
      renewing_group = @renewing_plan_year.benefit_groups.first

      if default_benefit_group.blank? && @employer_profile.plan_years.published.any?
        default_benefit_group = @employer_profile.plan_years.published.first.benefit_groups.first
      end

      @employer_profile.census_employees.non_terminated.exists("benefit_group_assignments" => false).each do |ce|
        ce.add_benefit_group_assignment(default_benefit_group, default_benefit_group.start_on)
        ce.add_renew_benefit_group_assignment(renewing_group)
        ce.save!
      end

      @employer_profile.census_employees.non_terminated.each do |ce|
        begin
          @logger.debug "renewing: #{ce.full_name}"
          person = Person.where(encrypted_ssn: Person.encrypt_ssn(ce.ssn)).first

          if person.blank?
            employee_role, family = Factories::EnrollmentFactory.add_employee_role({
              first_name: ce.first_name,
              last_name: ce.last_name,
              ssn: ce.ssn, 
              dob: ce.dob,
              employer_profile: @employer_profile,
              gender: ce.gender,
              hired_on: ce.hired_on
              })
            @logger.debug "created person record for #{ce.full_name}"
          else
            family = person.primary_family
          end

          if family.present?
            factory = Factories::FamilyEnrollmentRenewalFactory.new
            factory.family = family
            factory.census_employee = ce
            factory.employer = @employer_profile
            factory.renewing_plan_year = @renewing_plan_year
            if factory.renew
              @logger.debug " renewed: #{ce.full_name}"
            end
          else
            @logger.debug "family missing for #{ce.full_name}"
          end
        rescue Exception => e
          @logger.debug "Renewal failed for #{ce.full_name} due to #{e.to_s}"
        end
      end
    end
  end
end