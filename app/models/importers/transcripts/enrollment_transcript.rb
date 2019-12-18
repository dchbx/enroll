module Importers::Transcripts
  
  class StaleRecordError < StandardError; end
  class AmbiguousMatchError < StandardError; end
  class PersonMissingError < StandardError; end

  class EnrollmentTranscript

    attr_accessor :transcript, :updates, :market, :other_enrollment
    include ::Transcripts::EnrollmentCommon
    include ::Importers::Transcripts::EnrollmentActions

    ENUMERATION_FIELDS = {
      plan: { enumeration_field: "hios_id", enumeration: [ ]},
      hbx_enrollment_members: { enumeration_field: "hbx_id", enumeration: [ ]},
      broker: { enumeration_field: "npn", enumeration: [ ]}
    }

    SOURCE_RULE_MAP = {
      base: {
        add: {
          terminated_on: 'edi'
        },
        update: {
          applied_aptc_amount: 'ignore',
          terminated_on: 'edi',
          coverage_kind: 'ignore',
          hbx_id: 'edi',
          effective_on: 'edi'
        },
        remove: {
          terminated_on: 'edi'
        }
      },
      plan: {
        add: 'edi',
        update: 'edi',
        remove: 'ignore'
      },
      hbx_enrollment_members: {
        add: 'edi',
        update: 'edi',
        remove: {
          hbx_id: 'edi'
        }
      },
      broker: {
        add: 'ignore',
        update: 'ignore',
        remove: 'ignore'
      },
      enrollment: {
        remove: 'ignore'
      }
    }

    def process
      @canceled = false
      @member_changed = false
      @canceled = true if @other_enrollment.subscriber.coverage_end_on.present? && (@other_enrollment.subscriber.coverage_start_on >= @other_enrollment.subscriber.coverage_end_on)

      @other_enrollment = fix_enrollment_coverage_start(@other_enrollment)
      
      @updates = {}
      @comparison_result = ::Transcripts::ComparisonResult.new(@transcript)

      @enrollment = find_instance

      if @transcript[:source_is_new]
        if valid_new_request?
          create_new_enrollment
          @enrollment ||= @new_enrollment
        end
      end

      if true
        begin
          validate_update

          @comparison_result.changeset_sections.each do |section|
            actions = @comparison_result.changeset_section_actions [section]
            actions.each do |action|
              attributes = @comparison_result.changeset_content_at [section, action]
              if section != :enrollment && section != :new
                send(action, section, attributes)
              elsif section == :enrollment
                if action == 'remove'
                  @updates[:remove] ||={}
                  @updates[:remove][:enrollment] ||={}
                  send("process_enrollment_#{action}", attributes)
                else
                  log_ignore(action.to_sym, section, 'hbx_id')
                end
              end
            end
          end

          if @enrollment.present?
            if !@transcript[:source_is_new] # && @enrollment.updated_at <= Date.new(2016,11,9)
              if @canceled
                @enrollment.invalidate_enrollment! if @enrollment.may_invalidate_enrollment?
              elsif @other_enrollment.terminated_on.present? 
                if HbxEnrollment::ENROLLED_STATUSES.include?(@enrollment.aasm_state)
                  if @enrollment.may_terminate_coverage?
                    @enrollment.update!(terminated_on: @other_enrollment.terminated_on)
                    @enrollment.terminate_coverage!
                    @updates['match:enrollment'] = ["Success", "Terminated #{@enrollment.hbx_id}."]
                  else
                    @updates['match:enrollment'] = ["Failed", "Terminated #{@enrollment.hbx_id}."]
                  end
                end
              elsif HbxEnrollment::TERMINATED_STATUSES.include?(@enrollment.aasm_state)
                @enrollment.update!(terminated_on: nil)
                @enrollment.update!(aasm_state: 'coverage_selected')
                @updates['match:enrollment'] = ["Success", "Made #{@enrollment.hbx_id} coverage selected."]
              end
            end
          end
        rescue Exception => e
          @updates[:update_failed] = ['Merge Failed', e.to_s]
        end
      end
    end

    def valid_new_request?
      begin
        validate_other_enrollment
        
        @other_enrollment.hbx_enrollment_members.each do |member| 
          matched_people = match_person_instance(member.family_member.person)

          if matched_people.size > 1
            raise AmbiguousMatchError, "Found multiple people matches for #{member.family_member.person.first_name} #{member.family_member.person.last_name}."
          end

          if matched_people.size == 0
            raise PersonMissingError, "Matching person not found for #{member.family_member.person.first_name} #{member.family_member.person.last_name}."
          end
        end

        true
      rescue Exception => e
        @updates[:update_failed] = ['Merge Failed', e.to_s]
        return false
      end
    end

    def validate_other_enrollment
      if @other_enrollment.hbx_enrollment_members.empty?
        raise "EDI policy missing enrollees."
      end

      if @other_enrollment.subscriber.blank?
        raise "EDI policy missing subscriber."
      end

      if @market != 'shop'
        # active_year = @other_enrollment.plan.active_year
        # if  active_year != TimeKeeper.datetime_of_record.year
        #   raise "EDI policy has  #{active_year} plan."
        # end
      end
    end

    def validate_update
      validate_other_enrollment

      @comparison_result.changeset_sections.each do |section|
        actions = @comparison_result.changeset_section_actions [section]
        actions.each do |action|
          attributes = @comparison_result.changeset_content_at [section, action]

          attributes.each do |attribute, value|
            # TODO: should we ignore this
            # if section == :base && action == 'update' && attribute == 'effective_on'
            #   if @enrollment.coverage_terminated? || @enrollment.coverage_canceled?
            #     raise "Update failed. Enrollment is in #{@enrollment.aasm_state.camelcase} state."
            #   end
            # end

            if section == :plan && action == 'add'
              @plan = Plan.where(hios_id: @other_enrollment.plan.hios_id, active_year: @other_enrollment.plan.active_year).first
              if @plan.blank?
                raise "Plan not found with HIOS ID #{association['hios_id']} for year #{association['active_year']}."
              end
            end

            if section == :hbx_enrollment_members
              if action != 'remove'

                # if @enrollment.updated_at > Date.new(2016,11,9)
                #   raise "Enrollment last updated on #{@enrollment.updated_at.strftime('%m/%d/%Y')}."
                # end

                hbx_id = (action == 'add' ? value["hbx_id"] : attribute.split(':')[1])            
                enrollment_member = @other_enrollment.hbx_enrollment_members.detect{|em| em.hbx_id == hbx_id}

                matched_people = match_person_instance(enrollment_member.person)

                if matched_people.blank?
                  raise PersonMissingError, 'Hbx Enrollment member person record missing in EA.'
                end

                if matched_people.size > 1
                  raise AmbiguousMatchError, 'Hbx Enrollment member matched with multiple people in EA.'
                end
              end
            end

            if section == :enrollment
            end
          end
        end
      end
    end

    def add(section, attributes)
      rule = find_rule_set(section, :add)

      @updates[:add] ||= {} 
      @updates[:add][section] ||= {}

      if section == :base
        attributes.each do |field, value|
          if rule == 'edi' || (rule.is_a?(Hash) && rule[field.to_sym] == 'edi')
            begin
              send("add_#{field}", value)
              log_success(:add, section, field)
            rescue Exception => e
              @updates[:add][section][field] = ["Failed", "#{e.inspect}"]
            end
          else
            log_ignore(:add, section, field)
          end
        end
      else
        enumerated_association = ENUMERATION_FIELDS[section]

        attributes.each do |identifier, association|
          if rule == 'edi'
            begin
              send("add_#{section}", association)
              log_success(:add, section, identifier)
            rescue Exception => e 
              @updates[:add][section][identifier] = ["Failed", "#{e.inspect}"]
            end
          else
            log_ignore(:add, section, identifier)
          end
        end
      end
    end

    def update(section, attributes)
      rule = find_rule_set(section, :update)

      @updates[:update] ||= {} 
      @updates[:update][section] ||= {} 

      if section == :base
        attributes.each do |field, value|
          if value.present? && (rule == 'edi' || (rule.is_a?(Hash) && rule[field.to_sym] == 'edi'))
            begin
              send("update_#{field}", value)
              log_success(:update, section, field) if @updates[:update][section][field].blank?
            rescue Exception => e
              @updates[:update][section][field] = ["Failed", "#{e.inspect}"]
            end
          else
            log_ignore(:update, section, field)
          end
        end
      else
        enumerated_association = ENUMERATION_FIELDS[section]

        attributes.each do |identifier, value|
          if rule == 'edi'

            value.each do |key, v|
              if (key == 'add' || key == 'update') && section == :hbx_enrollment_members

                begin
                  member_hbx_id = identifier.split(':')[1]
                  member = @enrollment.hbx_enrollment_members.detect{|e| e.hbx_id == member_hbx_id}
                  if member.blank?
                    raise "Family member with hbx id #{member_hbx_id} missing."
                  end
                  member.update_attributes(v)
                  log_success(:update, section, identifier)
                rescue Exception => e
                  @updates[:update][section][identifier] = ["Failed", "#{e.inspect}"]
                end

              else
                log_ignore(:update, section, identifier)
              end
            end
          else
            log_ignore(:update, section, identifier)
          end
        end
      end
    end

    def remove(section, attributes)
      rule = find_rule_set(section, :remove)

      @updates[:remove] ||= {} 
      @updates[:remove][section] ||= {} 

      if section == :base
        attributes.each do |field, value|
          if rule == 'edi' || (rule.is_a?(Hash) && rule[field.to_sym] == 'edi')
            begin
              send("remove_#{field}", value)
              log_success(:remove, section, field)
            rescue Exception => e
              @updates[:remove][section][field] = ["Failed", "#{e.inspect}"]
            end
          else
            log_ignore(:remove, section, field)
          end
        end
      else
        enumerated_association = ENUMERATION_FIELDS[section]
        attributes.each do |identifier, value|
          if rule == 'edi' || (rule.is_a?(Hash) && rule[identifier.to_sym] == 'edi')
            begin
              send("#{section}_#{identifier}_remove", value)
              log_success(:remove, section, identifier)
            rescue Exception => e
              @updates[:remove][section][identifier] = ["Failed", "#{e.inspect}"]
            end
          else
            log_ignore(:remove, section, identifier)
          end
        end
      end
    end

    private

    def log_success(action, section, field)
      kind = (section == :base ? 'attribute' : 'record')
      @updates[action][section][field] = case action
      when :add
        ["Success", "Added #{field} #{kind} on #{section} using EDI source"]
      when :update
        ["Success", "Updated #{field} #{kind} on #{section} using EDI source"]
      else
        ["Success", "Removed #{field} on #{section}"]
      end
    end

    def log_ignore(action, section, field)
      @updates[action] ||= {}
      @updates[action][section] ||= {}
      @updates[action][section][field] = ["Ignored", "Ignored per Enrollment update rule set."]
    end

    def find_rule_set(section, action)
      SOURCE_RULE_MAP[section][action]
    end

    def find_instance
      ::HbxEnrollment.find(@transcript[:source]['_id'])
    end

    def create_new_enrollment
      @updates[:new] ||= {} 
      @updates[:new][:new] ||= {} 

      begin
        subscriber = @other_enrollment.family.primary_applicant
        matched_people = match_person_instance(subscriber.person)

        if matched_people.size > 1
          raise AmbiguousMatchError, 'Found multiple people in EA with given subscriber.'
        end

        if matched_people.size == 0
          raise PersonMissingError, 'Matching person not found.'
        end

        matched_person = matched_people.first
        if @market == 'individual'
          families = Family.find_all_by_person(matched_person)

          if families.present?
            if families.size  == 1
              family = families.first 
            else
              # TODO: pick the family where matched person is primary
              # if they're not primary(Responsible party), lookup other members on the enrollment with families.
              # if other mmembers match, pick that family. If they don't create a new family
            end
          end

          if family.blank?
            if matched_person.age_on(@other_enrollment.effective_on) < 18
              raise 'Unknown primary member -- subscriber is < 18 years old'
            end
            role = Factories::EnrollmentFactory.build_consumer_role(matched_person, false)
            if matched_person.save
              role.save
              matched_person.reload
              family = matched_person.primary_family
            else
              raise "unable to update person"
            end      
          end
        else
          employer_profile = EmployerProfile.find_by_fein(@other_enrollment.employer_profile.fein)
          if employer_profile.blank?
            raise 'EmployerProfile missing!'
          end

          employee_role = matched_person.active_employee_roles.detect{|e_role| e_role.employer_profile == employer_profile}
          if employee_role.present?
            census_employee = employee_role.census_employee
          else
            census_employees = CensusEmployee.matchable(matched_person.ssn, matched_person.dob).to_a + CensusEmployee.unclaimed_matchable(matched_person.ssn, matched_person.dob).to_a
            census_employees = census_employees.select{|ce| ce.employer_profile == employer_profile}

            if census_employees.size > 1
              raise "found multiple roster entrees for #{matched_person.full_name}"
            end

            if census_employees.blank?
              raise "unable to find census employee record"
            end

            census_employee = census_employees.first
          end

          role, family = Factories::EnrollmentFactory.build_employee_role(matched_person, false, employer_profile, census_employee, census_employee.hired_on)
          employee_role ||= role
        end

        plan = @other_enrollment.plan
        ea_plan = Plan.where(hios_id: plan.hios_id, active_year: plan.active_year).first
        if ea_plan.blank?
          raise "Plan with hios_id #{plan.hios_id} not found in EA."
        end

        hbx_id = HbxEnrollment.by_hbx_id(@other_enrollment.hbx_id).present? ? nil : @other_enrollment.hbx_id

        hbx_enrollment = family.active_household.hbx_enrollments.build({
          hbx_id: hbx_id,
          kind: @other_enrollment.kind,
          elected_aptc_pct: @other_enrollment.elected_aptc_pct,
          applied_aptc_amount: @other_enrollment.applied_aptc_amount,
          coverage_kind: @other_enrollment.coverage_kind, 
          effective_on: @other_enrollment.effective_on,
          terminated_on: @other_enrollment.terminated_on,
          submitted_at: TimeKeeper.datetime_of_record,
          created_at: TimeKeeper.datetime_of_record,
          updated_at: TimeKeeper.datetime_of_record
        })

        if @market == 'individual'
          hbx_enrollment.consumer_role_id =  matched_person.consumer_role.try(:id)
        else
          benefit_group, benefit_group_assignment = employee_current_benefit_group(employee_role, hbx_enrollment)
          if benefit_group.blank? || benefit_group_assignment.blank?
            raise 'unable to find employer sponsored benefits for the employee'
          end
          hbx_enrollment.benefit_group_id = benefit_group.id
          hbx_enrollment.benefit_group_assignment_id = benefit_group_assignment.id
          hbx_enrollment.employee_role_id = employee_role.id
        end

        hbx_enrollment.plan = ea_plan
        hbx_enrollment.aasm_state = 'coverage_selected'

        @other_enrollment.hbx_enrollment_members.each do |member| 

          matched_people = match_person_instance(member.family_member.person)

          if matched_people.size > 1
            raise AmbiguousMatchError, "Found multiple people matches for #{member.family_member.person.first_name} #{member.family_member.person.last_name}."
          end

          if matched_people.size == 0
            raise PersonMissingError, "Matching person not found for #{member.family_member.person.first_name} #{member.family_member.person.last_name}."
          end

          matched_person = matched_people.first
          if @market == 'individual'
            if matched_person.consumer_role.blank?
              consumer_role = matched_person.build_consumer_role(ssn: matched_person.ssn,
               dob: matched_person.dob,
               gender: matched_person.gender,
               is_incarcerated: matched_person.is_incarcerated,
               is_applicant: member.is_subscriber
               )

              if matched_person.save
                consumer_role.save
              else
                raise "unable to update person"
              end
            end
          end

          family_member = family.add_family_member(matched_person, is_primary_applicant: false)
          hbx_enrollment.hbx_enrollment_members.build({
            applicant_id: family_member.id,
            is_subscriber: member.is_subscriber,
            eligibility_date: member.coverage_start_on,
            coverage_start_on: member.coverage_start_on,
            coverage_end_on: member.coverage_end_on
          })
        end

        family.save!

        if @canceled
          hbx_enrollment.invalidate_enrollment! if hbx_enrollment.may_invalidate_enrollment?
        elsif @other_enrollment.terminated_on.present?
          hbx_enrollment.update!(terminated_on: @other_enrollment.terminated_on)
          hbx_enrollment.terminate_coverage!
        end

        @new_enrollment = hbx_enrollment
        @updates[:new][:new]['hbx_id'] = ["Success", "Enrollment added successfully using EDI source"]
      rescue Exception => e
        @updates[:new][:new]['hbx_id'] = ["Failed", "#{e.inspect}"]
      end
    end

    def find_plan_year_by_effective_date(employer_profile, target_date)
      plan_years = employer_profile.plan_years

      plan_year = (plan_years.published + plan_years.renewing_published_state + plan_years.where(:aasm_state.in => ["expired", "terminated"])).detect do |py|
        (py.start_on.beginning_of_day..py.end_on.end_of_day).cover?(target_date)
      end

      (plan_year.present? && plan_year.external_plan_year?) ? renewing_published_plan_year : plan_year
    end

    def employee_current_benefit_group(employee_role, hbx_enrollment)
      effective_date = hbx_enrollment.effective_on
      plan_year = find_plan_year_by_effective_date(employee_role.employer_profile, effective_date)
      
      if plan_year.present?

        if plan_year.open_enrollment_start_on > TimeKeeper.date_of_record
          raise "Open enrollment for your employer-sponsored benefits not yet started. Please return on #{plan_year.open_enrollment_start_on.strftime("%m/%d/%Y")} to enroll for coverage."
        end

        census_employee = employee_role.census_employee
        benefit_group_assignment = census_employee.active_benefit_group_assignment

        if benefit_group_assignment.blank? || benefit_group_assignment.plan_year != plan_year
          census_employee.add_benefit_group_assignment(plan_year.benefit_groups.first, plan_year.start_on)
          census_employee.save!
          benefit_group_assignment = census_employee.benefit_group_assignments.detect{|assignment| assignment.benefit_group == plan_year.benefit_groups.first}
        end

        return benefit_group_assignment.benefit_group, benefit_group_assignment
      else
        raise "Unable to find employer-sponsored benefits for enrollment year #{effective_date.year}"
      end
    end
  end
end