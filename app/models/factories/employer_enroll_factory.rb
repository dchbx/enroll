module Factories
  class EmployerEnrollFactory

    attr_accessor :employer_profile, :date

    def initialize
      @logger = Logger.new("#{Rails.root}/log/employer_enroll_factory_logfile.log")
    end

    def begin
      @logger.debug "Processing for begin #{employer_profile.legal_name}"
      published_plan_years = @employer_profile.plan_years.published_or_renewing_published.select do |plan_year|
        (plan_year.start_on..plan_year.end_on).cover?(@date || TimeKeeper.date_of_record)
      end

      if published_plan_years.size > 1
        @logger.debug "Found more than 1 published plan year for #{employer_profile.legal_name}"
        return
      end

      if published_plan_years.empty?
        @logger.debug "Published plan year missing for #{employer_profile.legal_name}."
        return
      end

      current_plan_year = published_plan_years.first
      if current_plan_year.may_activate?
        begin_coverage_for_employees(current_plan_year)
        current_plan_year.activate!

        if @employer_profile.may_enroll_employer?
          @employer_profile.enroll_employer!
        elsif @employer_profile.may_force_enroll?
          @employer_profile.force_enroll!
        end
      end
    end

    def end
      @logger.debug "Processing for end #{employer_profile.legal_name}"
      expiring_plan_years = @employer_profile.plan_years.published_or_renewing_published.where(:"end_on".lt => (@date || TimeKeeper.date_of_record))
      expiring_plan_years.no_timeout.each do |expiring_plan_year|
        begin
          expire_plan_year_enrollments_and_bgas(expiring_plan_year)
        rescue => e
          @logger.debug "Cannot process plan_year with id: #{expiring_plan_year.id.to_s}"
        end
      end
      @logger.debug "Done processing #{@employer_profile.legal_name}"
    end

    private

    def begin_coverage_for_employees(current_plan_year)
      id_list = current_plan_year.benefit_groups.collect(&:_id).uniq


      families = Family.where(:"households.hbx_enrollments" => {:$elemMatch => {
        :benefit_group_id.in => id_list,
        :effective_on => current_plan_year.start_on,
        :aasm_state.in => enrollment_statuses
      }})

      families.no_timeout.each do |family|
        enrollments = family.active_household.hbx_enrollments.select do |e| 
          enrollment_statuses.include?(e.aasm_state) && e.effective_on == current_plan_year.start_on && id_list.include?(e.benefit_group_id)
        end

        HbxEnrollment::COVERAGE_KINDS.each do |coverage_kind|
          enrollments_by_kind = enrollments.select{|e| e.coverage_kind == coverage_kind }
          next if enrollments_by_kind.blank?

          enrollment = enrollments_by_kind.first
          if enrollments_by_kind.size > 1
            enrollment = enrollments_by_kind.sort_by(&:created_at).last
            enrollments_by_kind.each do |e|
              next if e.hbx_id == enrollment.hbx_id
              e.cancel_coverage! if e.may_cancel_coverage?
            end
          end

          if enrollment.benefit_group_assignment_id.blank?
            @logger.debug "Benefit group assignment missing for Enrollment: #{enrollment.hbx_id}."
            next
          end
          benefit_group_assignment = enrollment.benefit_group_assignment

          if enrollment.may_begin_coverage?
            enrollment.begin_coverage!
            if enrollment.is_coverage_waived?
              benefit_group_assignment.waive_benefit
            else
              benefit_group_assignment.begin_benefit
            end
          end
        end
      end
    end

    def expire_plan_year_enrollments_and_bgas(expiring_plan_year)
      bg_ids = expiring_plan_year.benefit_groups.collect(&:_id).uniq
      query = { :benefit_group_id.in => bg_ids }
      families = Family.where("households.hbx_enrollments" => {:$elemMatch => query})

      families.no_timeout.each do |family|
        begin
          family.active_household.hbx_enrollments.enrolled_and_renewing.where(query).each do |enrollment|
            begin
              enrollment.expire_coverage! if enrollment.may_expire_coverage?
              if enrollment.benefit_group_assignment_id.present?
                assignment = enrollment.benefit_group_assignment
                assignment.expire_coverage! if assignment.may_expire_coverage?
                assignment.update_attributes(is_active: false) if assignment.is_active?
              end
            rescue Exception => e
              @logger.debug "Exception #{e.backtrace} occured for enrollment with hbx_id #{enrollment.hbx_id}"
            end
          end
        rescue => e
          @logger.debug "Cannot process enrollments for family with id: #{family.id}, primary_person_hbx_id: #{family.primary_person.hbx_id}, Error: #{e.backtrace}"
        end
      end
      expiring_plan_year.expire! if expiring_plan_year.may_expire?
    end

    def enrollment_statuses
      HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES + HbxEnrollment::WAIVED_STATUSES
    end
  end 
end
