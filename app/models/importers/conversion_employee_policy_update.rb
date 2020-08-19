module Importers
  class ConversionEmployeePolicyUpdate < ConversionEmployeePolicyCommon

    validate :validate_benefit_group_assignment
    validate :validate_census_employee
    validate :validate_fein
    validate :validate_plan
    validates_length_of :fein, is: 9
    validates_length_of :subscriber_ssn, is: 9
    validates_presence_of :hios_id

    def validate_fein
      return true if fein.blank?
      found_employer = find_employer
      if found_employer.nil?
        errors.add(:fein, "does not exist")
      end
    end

    def validate_census_employee
      return true if subscriber_ssn.blank?
      found_employee = find_employee
      if found_employee.nil?
        errors.add(:subscriber_ssn, "no census employee found")
      end
    end

    def validate_benefit_group_assignment
      return true if subscriber_ssn.blank?
      found_employee = find_employee
      return true unless find_employee
      found_bga = find_benefit_group_assignment
      if found_bga.nil?
        errors.add(:subscriber_ssn, "no benefit group assignment found")
      end
    end

    def validate_plan
      return true if hios_id.blank?
      found_plan = find_plan
      if found_plan.nil?
        errors.add(:hios_id, "no plan found with hios_id #{hios_id} and active year #{plan_year}")
      end
    end

    def find_employee
      return @found_employee unless @found_employee.nil?
      return nil if subscriber_ssn.blank?
      found_employer = find_employer
      return nil if found_employer.nil?
      candidate_employees = CensusEmployee.where({
        employer_profile_id: found_employer.id,
        # hired_on: {"$lte" => start_date},
        encrypted_ssn: CensusMember.encrypt_ssn(subscriber_ssn)
      })
      non_terminated_employees = candidate_employees.reject do |ce|
        (!ce.employment_terminated_on.blank?) && ce.employment_terminated_on <= Date.today
      end
    
      @found_employee = non_terminated_employees.sort_by(&:hired_on).last
    end

    def find_plan 
      return @plan unless @plan.nil?
      return nil if hios_id.blank?
      clean_hios = hios_id.strip
      corrected_hios_id = (clean_hios.end_with?("-01") ? clean_hios : clean_hios + "-01")
      @plan = Plan.where({
        active_year: plan_year.to_i,
        hios_id: corrected_hios_id
      }).first
    end

    def find_employer
      return @found_employer unless @found_employer.nil?
      org = Organization.where(:fein => fein).first
      return nil unless org
      @found_employer = org.employer_profile
    end

    PersonSlug = Struct.new(:name_pfx, :first_name, :middle_name, :last_name, :name_sfx, :ssn, :dob, :gender)

    def find_person
      employee = find_employee

      role = employee.employee_role
      person = role.try(:person)

      if person.blank?
        people = Person.where(:'employee_roles.census_employee_id' => employee.id)

        if people.size > 1
          errors.add(:base, "found mutliple people linked to the census employee record")
          return false
        end

        person = people.first
      end

      if person.blank?
        errors.add(:base, "unable to find person")
        return false
      end

      person
    end

    def find_current_enrollment(family, employer)
      plan_year = employer.plan_years.published_and_expired_plan_years_by_date(employer.registered_on).first

      if plan_year.blank?
        errors.add(:base, "plan year missing")
        return false
      end

      enrollments = family.active_household.hbx_enrollments.where({
        :benefit_group_id.in => plan_year.benefit_group_ids,
        :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES + ["coverage_expired"]
        }).by_coverage_kind('health').order(created_at: :desc).to_a

      if enrollments.empty?
        errors.add(:base, "enrollment missing!")
        return false
      end
  
      enrollment = enrollments.shift

      # if enrollments.size > 1
      #   errors.add(:base, "more than 1 enrollment found for given benefit groups")
      #   return false
      # end

      enrollments.each do |enrollment|
        enrollment.cancel_coverage! if enrollment.may_cancel_coverage?
      end

      enrollment.expire_coverage! if enrollment.may_expire_coverage?
      enrollment
    end

    def person_relationship_for(census_relationship)
      case census_relationship
      when "spouse"
        "spouse"
      when "domestic_partner"
        "life_partner"
      when "child_under_26", "child_26_and_over", "disabled_child_26_and_over"
        "child"
      end
    end

    def get_passively_renewed_coverage(employer, family)
      renewed_plan_year = employer.renewing_published_plan_year
      if expired_plan_year = employer.plan_years.where(:aasm_state => 'expired').first
        renewed_plan_year = employer.plan_years.where({
          :start_on => (expired_plan_year.start_on + 1.year), 
          :aasm_state.in => PlanYear::RENEWING_PUBLISHED_STATE + PlanYear::PUBLISHED}).first
      end
    
      if renewed_plan_year.blank?
        warnings.add(:base, "renewed/renewing plan year missing")
        return true
      end

      enrollments = family.active_household.hbx_enrollments.where({
        :benefit_group_id.in => renewed_plan_year.benefit_group_ids,
        :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES + HbxEnrollment::RENEWAL_STATUSES
        }).by_coverage_kind('health')

      if enrollments.empty?
        warnings.add(:base, "renewal enrollment missing!")
        return true
      end

      renewal_enrollments = enrollments.select{|e| e.auto_renewing? || e.workflow_state_transitions.where(:to_state => 'auto_renewing').present?}
      
      if (enrollments - renewal_enrollments).present?
        warnings.add(:base, "employee already made plan selection")
        return true
      end

      if renewal_enrollments.size > 1
        errors.add(:base, "more than 1 passive renewal found for given benefit groups")
        return false
      end

      renewal_enrollments.first
    end

    def update_coverage_dependents(family, enrollment, employer, plan)
      people = map_dependents.inject([]) do |people, dependent|

        matched = Person.match_by_id_info(ssn: dependent.ssn, dob: dependent.dob, last_name: dependent.last_name, first_name: dependent.first_name)
        primary = enrollment.subscriber.person

        if matched.empty?
          alternate_member = alternate_family_member_record(family, dependent)
          if dependent.ssn.present? && alternate_member.present? && alternate_member.person.ssn != dependent.ssn
            alternate_member.person.update_attributes(ssn: dependent.ssn)
          end

          people << (alternate_member.present? ? alternate_member.person : Factories::EnrollmentFactory.initialize_dependent(family, primary, dependent))
        else
          person = matched.detect{|match| family.find_family_member_by_person(match).present? }

          if person.blank?
            relationship = person_relationship_for(dependent.employee_relationship)
            primary.ensure_relationship_with(matched[0], relationship, family.id)
            family.add_family_member(matched[0])
          end

          people << (person || matched[0])
        end
      end

      family.save!
      family.reload
      enrollment.reload

      filter_people_for_removal = Proc.new{|enrollment, people|
        enrollment.hbx_enrollment_members.inject([]){|people_to_delete, enrollment_member| 
          (people + [enrollment.subscriber.person]).include?(enrollment_member.person) ? people_to_delete : (people_to_delete << enrollment_member.person)
        }
      }

      people_for_removal = filter_people_for_removal.call(enrollment, people)
      if update_enrollment_members(family, enrollment, people)

        passive_renewal = get_passively_renewed_coverage(employer, family)
        return passive_renewal if passive_renewal.is_a?(Boolean)
        people_for_removal += filter_people_for_removal.call(passive_renewal, people)

        if update_enrollment_members(family, passive_renewal, people, true)
          people_for_removal.uniq.each do |person|
            family_member = family.find_family_member_by_person(person)
            next if family_member.blank?
            next if family.active_household.hbx_enrollments.where("hbx_enrollment_members.applicant_id" => family_member.id).present?
            family.active_household.remove_family_member(family_member)
            family_member.delete
          end

          return true
        end
      end

      false
    end

    def alternate_family_member_record(family, fm)
      family.family_members.detect do |family_member|
        family_member.first_name.match(/#{fm.first_name}/i) && family_member.last_name.match(/#{fm.last_name}/i) && family_member.dob == fm.dob
      end
    end

    def replace_enrollment_member(enrollments, family_member, alternate_member)
      enrollments.each do |enrollment|
        enrollment_members = enrollment.hbx_enrollment_members
        enrollment_members.reject!{|em| em.family_member == family_member}
        enrollment_members << enrollment.hbx_enrollment_members.build({
          applicant_id: alternate_member.id, eligibility_date: enrollment.effective_on, coverage_start_on: enrollment.effective_on
        })

        enrollment.hbx_enrollment_members = enrollment_members
        enrollment.save
      end
    end

    def update_enrollment_members(family, enrollment, people, passive=false)
      added = []
      dropped = []

      enrollment_members = enrollment.hbx_enrollment_members.select{|em| em.is_subscriber? }
      hh = family.active_household
      ch = hh.immediate_family_coverage_household

      people.each do |person|
        enrollment_member = enrollment.hbx_enrollment_members.detect{|em| em.person == person}
        if enrollment_member.blank?
          family_member = family.find_family_member_by_person(person)
          family.active_household.add_household_coverage_member(family_member)
          family.save

          enrollment_member = enrollment.hbx_enrollment_members.build({
            applicant_id: family_member.id, eligibility_date: enrollment.effective_on, coverage_start_on: enrollment.effective_on
          })
          added << "#{family_member.person.full_name}"
        end

        enrollment_members << enrollment_member if enrollment_member
      end

      enrollment.hbx_enrollment_members.each do |enrollment_member|
        if !people.include?(enrollment_member.person) && !enrollment_member.is_subscriber?
          dropped << "#{enrollment_member.person.full_name}(#{enrollment_member.person.ssn})"
        end
      end

      enrollment.hbx_enrollment_members = enrollment_members

      if enrollment.save
        family.reload

        msg_str  = ""
        msg_str += "Added " + (added.join(',') + " to the #{'renewed' if passive} enrollment") if added.any?
        msg_str += "Dropped " + (dropped.join(',') + "from the #{'renewed' if passive} enrollment") if dropped.any?
        warnings.add(:base, msg_str) unless msg_str.blank?
        return true
      else
        enrollment.errors.each{|attr, err| errors.add("family_" + attr.to_s, err)}
        return false
      end
    end

    def map_dependent(dep_idx)
      last_name = self.send("dep_#{dep_idx}_name_last".to_sym)
      first_name = self.send("dep_#{dep_idx}_name_first".to_sym)
      middle_name = self.send("dep_#{dep_idx}_name_middle".to_sym)
      relationship = self.send("dep_#{dep_idx}_relationship".to_sym)
      dob = self.send("dep_#{dep_idx}_dob".to_sym)
      ssn = self.send("dep_#{dep_idx}_ssn".to_sym)
      gender = self.send("dep_#{dep_idx}_gender".to_sym)
      if [first_name, last_name, middle_name, relationship, dob, ssn, gender].all?(&:blank?)
        return nil
      end
      attr_hash = {
        first_name: first_name,
        last_name: last_name,
        dob: dob,
        employee_relationship: relationship,
        gender: gender
      }
      unless middle_name.blank?
        attr_hash[:middle_name] = middle_name
      end
      unless ssn.blank?
        if ssn == subscriber_ssn
          warnings.add("dependent_#{dep_idx}_ssn", "ssn same as subscriber, blanking for import")
        else
          attr_hash[:ssn] = ssn
        end
      end
      CensusDependent.new(attr_hash)
    end

    def map_dependents
      (1..8).to_a.map do |idx|
        map_dependent(idx)
      end.compact
    end

    def update_plan_for_passive_renewal(family, renewing_plan_year, renewal_plan)
      enrollments = family.active_household.hbx_enrollments.where(:benefit_group_id.in => renewing_plan_year.benefit_group_ids)

      if enrollments.enrolled.present?
        errors.add(:base, "employee already made plan selection")
        return false
      end

      if enrollments.renewing.size > 1
        errors.add(:base, "duplicate passive renewals found!")
        return false        
      end

      if enrollments.renewing.blank?
        return true
      else
        if renewal_plan.blank?
          errors.add(:base, "renewal plan missing!")
          return false  
        end
        enrollments.renewing.first.update_attributes(plan_id: renewal_plan.id)
        return true
      end
    end

    def save
      begin
        return false unless valid?
        employer = find_employer

        person = find_person
        return false unless person

        # puts '----processing ' + person.full_name

        family = person.primary_family
        enrollment = find_current_enrollment(family, employer)

        return false unless enrollment

        plan = find_plan
        return false unless update_coverage_dependents(family, enrollment, employer, plan)

        if enrollment.plan_id != plan.id
          enrollment.update_attributes(plan_id: plan.id)
          if renewing_plan_year = employer.plan_years.renewing.first
            update_plan_for_passive_renewal(family, renewing_plan_year, plan.renewal_plan)
          end
          return true
        else
          errors.add(:base, "already have coverage with same hios id")
          return false
        end
      rescue Exception => e
        errors.add(:base, e.to_s)
        return false
      end
    end

    def cancel_other_enrollments_for_bga(bga)
      enrollments = HbxEnrollment.find_enrollments_by_benefit_group_assignment(bga)
      enrollments.each do |en|
        en.hbx_enrollment_members.each do |hen|
           hen.coverage_end_on = hen.coverage_start_on
        end
        en.terminated_on = en.effective_on
        en.aasm_state = "coverage_canceled"
        en.save!
      end
    end
  end
end
