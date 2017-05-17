module Transcripts
  module EnrollmentCommon


    def self.included(base)
      base.extend ClassMethods
    end
   
    def fix_enrollment_coverage_start(enrollment)
      if enrollment.subscriber.coverage_end_on.blank?
        members_with_end_date = enrollment.hbx_enrollment_members.select{|m| m.coverage_end_on.present? }
        maximum_end_date = members_with_end_date.sort_by{|member| member.coverage_end_on}.reverse.first.try(:coverage_end_on)
        maximum_start_date = enrollment.hbx_enrollment_members.sort_by{|member| member.coverage_start_on}.reverse.first.coverage_start_on

        if maximum_end_date.present?
          enrollment.effective_on = [maximum_start_date, (maximum_end_date + 1.day)].max
        else
          enrollment.effective_on = maximum_start_date
        end

        # enrollment.hbx_enrollment_members.each do |member| 
        #   member.coverage_start_on = enrollment.effective_on
        # end

        enrollment.hbx_enrollment_members = enrollment.hbx_enrollment_members.reject{|member| member.coverage_end_on.present?}
      else
        enrollment.hbx_enrollment_members = enrollment.hbx_enrollment_members.reject{|member| member.coverage_end_on != enrollment.subscriber.coverage_end_on}
      end
      
      enrollment
    end

    def matching_ivl_coverages(enrollment, family=nil)
      family ||= enrollment.family

      family.active_household.hbx_enrollments.where({
        :coverage_kind => enrollment.coverage_kind, 
        :kind => enrollment.kind,
        :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES)
        }).order_by(:effective_on.asc)
        .select{|e| e.plan.active_year == enrollment.plan.active_year} #.reject{|en| en.void?}
        .reject{|en| en.subscriber.present? && enrollment.subscriber.present? && (en.subscriber.hbx_id != enrollment.subscriber.hbx_id)}
    end

    def matching_shop_coverages(enrollment, family=nil)
      if enrollment.persisted?
        assignment = enrollment.benefit_group_assignment
        benefit_group = (assignment.present? ? assignment.benefit_group : enrollment.benefit_group)
        if benefit_group.blank?
          id_list = []
        else
          id_list = benefit_group.plan_year.benefit_groups.collect(&:_id).uniq
        end
      else
        # TODO: Fix this for Conversion ER
        plan_year = enrollment.employer_profile.find_plan_year_by_effective_date(enrollment.effective_on)
        id_list = plan_year.benefit_groups.collect(&:_id).uniq if plan_year.present?
      end

      family ||= enrollment.family
      return [] if family.blank? || id_list.blank?

      family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).where({
        :coverage_kind => enrollment.coverage_kind, 
        :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES)
        }).order_by(:effective_on.asc).reject{|en| en.void?}
        .reject{|en| en.subscriber.hbx_id != enrollment.subscriber.hbx_id}
    end

    def match_person_instance(person)
      @people_cache ||= {}
      return @people_cache[person.hbx_id] if @people_cache[person.hbx_id].present?

      if person.hbx_id.present?
        matched_people = ::Person.where(hbx_id: person.hbx_id)
      end


      other_matched_people = ::Person.match_by_id_info(
            ssn: person.ssn,
            dob: person.dob,
            last_name: person.last_name,
            first_name: person.first_name
          )

      if other_matched_people.size > 1 && matched_people.size == 1
        if matched_people.first.families.blank?
          person_with_hbx_id = other_matched_people.detect{|p| p.families.present?}
          matched_people.first.delete
          person_with_hbx_id.update!(hbx_id: person.hbx_id)
          matched_people = [person_with_hbx_id]
        end
      end


      if matched_people.blank?
        matched_people = ::Person.match_by_id_info(
            ssn: person.ssn,
            dob: person.dob,
            last_name: person.last_name,
            first_name: person.first_name
          )
      end

      @people_cache[person.hbx_id] = matched_people
      matched_people
    end
  end
end