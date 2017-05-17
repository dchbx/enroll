module Importers::Transcripts

  module EnrollmentActions

    def add_terminated_on(termination_date)
      if termination_date > TimeKeeper.date_of_record
        @enrollment.schedule_coverage_termination! if @enrollment.may_schedule_coverage_termination?
      else
        @enrollment.terminate_coverage! if @enrollment.may_terminate_coverage?
      end

      @enrollment.update!({:terminated_on => termination_date})
    end    

    def add_plan(association)
      @plan ||= Plan.where(hios_id: association['hios_id'], active_year: association['active_year']).first

      build_new_hbx_enrollment
      @enrollment.plan = @plan
      @enrollment.save!
    end

    def update_plan(association)
      @plan ||= Plan.where(hios_id: association['hios_id'], active_year: association['active_year']).first
      
      build_new_hbx_enrollment
      @enrollment.plan = @plan
      @enrollment.save!
    end

    def add_hbx_enrollment_members(association)
      other_enrollment_member = @other_enrollment.hbx_enrollment_members.detect{|member| member.family_member.hbx_id == association['hbx_id']}
      matching_person = match_person_instance(other_enrollment_member.family_member.person).first

      build_new_hbx_enrollment

      family = @enrollment.family
      family_member = family.add_family_member(matching_person, is_primary_applicant: false)

      @enrollment.hbx_enrollment_members.build({
        applicant_id: family_member.id,
        is_subscriber: other_enrollment_member.is_subscriber,
        eligibility_date: other_enrollment_member.coverage_start_on,
        coverage_start_on: other_enrollment_member.coverage_start_on,
        coverage_end_on: other_enrollment_member.coverage_end_on
      })

      family.save!
      @member_changed = true
    end

    def build_new_hbx_enrollment
      return if @member_changed
      family = @enrollment.family

      hbx_enrollment = family.active_household.hbx_enrollments.build({
        kind: @enrollment.kind,
        elected_aptc_pct: @enrollment.elected_aptc_pct,
        applied_aptc_amount: @enrollment.applied_aptc_amount,
        coverage_kind: @enrollment.coverage_kind,
        effective_on: @other_enrollment.effective_on,
        terminated_on: @other_enrollment.terminated_on,
        submitted_at: TimeKeeper.datetime_of_record,
        created_at: TimeKeeper.datetime_of_record,
        updated_at: TimeKeeper.datetime_of_record
      })

      if @market == 'shop'
        hbx_enrollment.benefit_group_id = @enrollment.benefit_group_id
        hbx_enrollment.benefit_group_assignment_id = @enrollment.benefit_group_assignment_id
        hbx_enrollment.employee_role_id = @enrollment.employee_role_id
      else
        hbx_enrollment.consumer_role_id = @enrollment.consumer_role_id
      end

      @enrollment.hbx_enrollment_members.each do |member| 
        hbx_enrollment.hbx_enrollment_members.build(member.attributes.except('_id'))
      end

      hbx_enrollment.plan = @enrollment.plan
      hbx_enrollment.aasm_state = 'coverage_selected'
      hbx_enrollment.save!
      hbx_enrollment.reload

      if @canceled
        hbx_enrollment.invalidate_enrollment! if hbx_enrollment.may_invalidate_enrollment?
      elsif @other_enrollment.terminated_on.present?
        hbx_enrollment.update!(terminated_on: @other_enrollment.terminated_on)
        hbx_enrollment.terminate_coverage! if hbx_enrollment.may_terminate_coverage?
      end

      @enrollment.invalidate_enrollment! if @enrollment.may_invalidate_enrollment?
      @enrollment = hbx_enrollment
    end

    def update_effective_on(value)
      @enrollment.update!({:effective_on => value})
    end

    def update_terminated_on(value)
      @enrollment.update!({:terminated_on => value})

      if value > TimeKeeper.date_of_record
        @enrollment.schedule_coverage_termination! if @enrollment.may_schedule_coverage_termination?
      else
        @enrollment.terminate_coverage! if @enrollment.may_terminate_coverage?
      end
    end

    def update_hbx_id(hbx_id)
      if HbxEnrollment.by_hbx_id(hbx_id).blank?
        @enrollment.update!({:hbx_id => hbx_id})
      else
        @updates[:update][:base]['hbx_id'] = ["Success", "Add EDI DB foreign key #{@enrollment.hbx_id}"]
      end
    end

    def update_applied_aptc_amount(value)
      @enrollment.update!({:applied_aptc_amount => value})
    end
 
    def remove_terminated_on(value)
      @enrollment.update!({:terminated_on => nil})
      @enrollment.update!({:aasm_state => 'coverage_selected'})

      @enrollment.hbx_enrollment_members.each do |member|
        member.update!({coverage_end_on: nil})
      end
    end

    def hbx_enrollment_members_hbx_id_remove(value)
      build_new_hbx_enrollment
      @enrollment.hbx_enrollment_members.detect{|member| member.hbx_id == value['hbx_id'] }.delete
      @member_changed = true
    end

    def process_enrollment_remove(attributes)
      if @enrollment.blank?
        subscriber = @other_enrollment.family.primary_applicant
        matched_people = match_person_instance(subscriber.person)
        matched_person = matched_people.first
        family = Family.find_all_by_person(matched_person).first
      else
        family = @enrollment.family
      end

      attributes['hbx_id'].each do |enrollment_hash|
        if enrollment = family.active_household.hbx_enrollments.where(:hbx_id => enrollment_hash['hbx_id']).first
          if (HbxEnrollment::TERMINATED_STATUSES).include?(enrollment.aasm_state.to_s)
            @updates[:remove][:enrollment]["hbx_id:#{enrollment_hash['hbx_id']}"] = ["Ignored", "Enrollment already in #{enrollment.aasm_state}."]
          # elsif (enrollment.effective_on < @other_enrollment.effective_on) && (((@other_enrollment.hbx_enrollment_members <=> enrollment.hbx_enrollment_members) != 0) || (@other_enrollment.plan.id != enrollment.plan.id))
          #   enrollment.update!(terminated_on: (@other_enrollment.effective_on - 1.day))
          #   enrollment.terminate_coverage!
          #   @updates[:remove][:enrollment]["hbx_id:#{enrollment_hash['hbx_id']}"] = ["Success", "Enrollment terminated successfully"]
          else (enrollment.effective_on <= @other_enrollment.effective_on)
            enrollment.invalidate_enrollment! if enrollment.may_invalidate_enrollment?
            @updates[:remove][:enrollment]["hbx_id:#{enrollment_hash['hbx_id']}"] = ["Success", "Enrollment voided successfully"]
          end
        end
      end
    end

    def csv_row
      @people_cache = {}
      @plan = nil

      plan_details = (@transcript[:plan_details].present? ? @transcript[:plan_details].values : 4.times.map{nil})
      person_details = [
        @transcript[:primary_details][:hbx_id],
        @transcript[:primary_details][:ssn], 
        @transcript[:primary_details][:last_name], 
        @transcript[:primary_details][:first_name]
      ]

      details = person_details + plan_details
      if @market == 'shop'
        employer_details = (@transcript[:employer_details].present? ? @transcript[:employer_details].values : 3.times.map{nil})
        details += employer_details     
      end

      results = @comparison_result.changeset_sections.reduce([]) do |section_rows, section|
        actions = @comparison_result.changeset_section_actions [section]
        section_rows += actions.reduce([]) do |rows, action|
          attributes = @comparison_result.changeset_content_at [section, action]

          fields_to_ignore = ['_id', 'updated_by']
          rows = []
          attributes.each do |attribute, value|
            if value.is_a?(Hash)
              fields_to_ignore.each{|key| value.delete(key) }
              value.each{|k, v| fields_to_ignore.each{|key| v.delete(key) } if v.is_a?(Hash) }
            end

            if @updates[:update_failed].present?
              action_taken = @updates[:update_failed]
            else
              if action.to_sym == :remove && section == :enrollment
                action_taken = ["Success", @updates[:remove][:enrollment].to_json]
              else
                action_taken = @updates[action.to_sym][section][attribute]
              end
            end

            if value.is_a?(Array)
              value.each do |val|
                rows << ([@transcript[:identifier]] + details + [action, "#{section}:#{attribute}", val] + (action_taken || []))
              end
            else
              rows << ([@transcript[:identifier]] + details + [action, "#{section}:#{attribute}", value] + (action_taken || []))
            end   
          end
          rows
        end
      end

      if results.empty?
        ([[@transcript[:identifier]] + details + ['update']])
      else
        results
      end
    end
  end
end