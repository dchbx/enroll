module Factories
  class EnrollmentFactory
    extend Acapi::Notifiers

    def self.add_consumer_role(person:, new_ssn: nil, new_dob: nil, new_gender: nil, new_is_incarcerated:, new_is_applicant:,
                               new_is_state_resident:, new_citizen_status:)

      [:new_is_incarcerated, :new_is_applicant, :new_is_state_resident, :new_citizen_status].each do |value|
        name = value.id2name
        raise ArgumentError.new("missing value: #{name}, expected as keyword ") if eval(name).blank?
      end

      ssn = new_ssn
      dob = new_dob
      gender = new_gender
      is_incarcerated = new_is_incarcerated
      is_applicant = new_is_applicant
      is_state_resident = new_is_state_resident
      citizen_status = new_citizen_status

      # Assign consumer-specifc attributes
      consumer_role = person.build_consumer_role(ssn: ssn,
                                                 dob: dob,
                                                 gender: gender,
                                                 is_incarcerated: is_incarcerated,
                                                 is_applicant: is_applicant,
                                                 is_state_resident: is_state_resident,
                                                 citizen_status: citizen_status)
     if person.save
        consumer_role.save
      else
        consumer_role.errors.add(:person, "unable to update person")
      end

     return consumer_role

    end

    def self.construct_consumer_role(person_params, user)
      person_params = person_params[:person]
      person, person_new = initialize_person(
        user, person_params["name_pfx"], person_params["first_name"],
        person_params["middle_name"] , person_params["last_name"],
        person_params["name_sfx"], person_params["ssn"].gsub("-",""),
        person_params["dob"], person_params["gender"], "consumer", person_params["no_ssn"]
        )
      if person.blank? && person_new.blank?
        begin
          raise
        rescue => e
          error_message = {
            :error => {
              :message => "unable to construct consumer role",
              :person_params => person_params.inspect,
              :user => user.inspect,
              :backtrace => e.backtrace.join("\n")
            }
          }
          log(JSON.dump(error_message), {:severity => 'error'})
        end
        return nil
      end
      role = build_consumer_role(person, person_new)
    end

    def self.build_consumer_role(person, person_new)
      role = find_or_build_consumer_role(person)
      family, primary_applicant =  initialize_family(person,[])
      family.family_members.map(&:__association_reload_on_person)
      saved = save_all_or_delete_new(family, primary_applicant, role)
      if saved
        role
      elsif person_new
        person.delete
      end
      return role
    end

    def self.find_or_build_consumer_role(person)
      return person.consumer_role if person.consumer_role.present?
      person.build_consumer_role(is_applicant: true)
    end

    def self.add_broker_role(person:, new_kind:, new_npn:, new_mailing_address:)

      [:new_kind, :new_npn, :new_mailing_address].each do |value|
        name = value.id2name

        raise ArgumentError.new("missing value: #{name}, expected as keyword ") if eval(name).blank?
      end

      kind = new_kind
      npn = new_npn

      mailing_address = new_mailing_address

      family, = self.initialize_family(person, [])

      broker_role = nil

      if person.broker_role.blank?
        # Assign broker-specifc attributes
        #broker_role = person.build_broker(mailing_address: mailing_address, npn: npn, kind: kind)
        broker_role = person.build_broker_role(npn: npn)
      end

      if person.save
        if family.save
          family.delete unless broker_role.save
        else
          broker_role.errors.add(:family, "unable to create family")
        end
      else
        broker_role.errors.add(:person, "unable to update person")
      end

      # Return new instance
      return broker_role

    end

    # Fix this method to utilize the following:
    # needs:
    #   an object that responds to the names and gender methods
    #   census_employee
    #   user
    def self.construct_employee_role(user, census_employee, person_details)
      person, person_new = initialize_person(
        user, person_details.name_pfx, person_details.first_name,
        person_details.middle_name, person_details.last_name,
        person_details.name_sfx, census_employee.ssn,
        census_employee.dob, person_details.gender, "employee"
        )
      return nil, nil if person.blank? && person_new.blank?
      self.build_employee_role(
        person, person_new, census_employee.employer_profile,
        census_employee, census_employee.hired_on
        )
    end

    def self.add_employee_role(user: nil, employer_profile:,
          name_pfx: nil, first_name:, middle_name: nil, last_name:, name_sfx: nil,
          ssn:, dob:, gender:, hired_on:
      )
      person, person_new = initialize_person(user, name_pfx, first_name, middle_name,
                                             last_name, name_sfx, ssn, dob, gender, "employee")

      census_employee = EmployerProfile.find_census_employee_by_person(person).first

      raise ArgumentError.new("census employee does not exist for provided person details") unless census_employee.present?
      raise ArgumentError.new("no census employee for provided employer profile") unless census_employee.employer_profile_id == employer_profile.id

      self.build_employee_role(
        person, person_new, employer_profile, census_employee, hired_on
        )
    end

    def self.link_census_employee(census_employee, employee_role, employer_profile)
      census_employee.employer_profile = employer_profile
      employee_role.employer_profile = employer_profile
      census_employee.benefit_group_assignments.each do |bga|
        if bga.coverage_selected? && bga.hbx_enrollment.present? && !bga.hbx_enrollment.inactive?
          bga.hbx_enrollment.employee_role_id = employee_role.id
          bga.hbx_enrollment.save
        end
      end
      census_employee.employee_role = employee_role
      employee_role.new_census_employee = census_employee
      employee_role.hired_on = census_employee.hired_on
      employee_role.terminated_on = census_employee.employment_terminated_on
    end
    
    def self.migrate_census_employee_contact_to_person(census_employee, person)
      if census_employee
        if census_employee.address
          person.addresses.create!(census_employee.address.attributes) if person.addresses.blank?
        end
        if census_employee.email
          person.emails.create!(census_employee.email.attributes) if person.emails.blank?
          person.emails.create!(kind: 'work', address: census_employee.email_address) if person.work_email.blank? && census_employee.email_address.present?
        end
      end
    end

    def self.build_employee_role(person, person_new, employer_profile, census_employee, hired_on)
      role = find_or_build_employee_role(person, employer_profile, census_employee, hired_on)
      self.link_census_employee(census_employee, role, employer_profile)
      family, primary_applicant = self.initialize_family(person, census_employee.census_dependents)
      family.family_members.map(&:__association_reload_on_person)
      saved = save_all_or_delete_new(family, primary_applicant, role)
      if saved
        census_employee.save
        migrate_census_employee_contact_to_person(census_employee, person)
      elsif person_new
        person.delete
      end
      
      return role, family
    end

    def self.build_family(person, dependents)
      #only build family if there is no primary family, otherwise return primary family
      if person.primary_family.nil?
        family, primary_applicant = self.initialize_family(person, dependents)
        family.family_members.map(&:__association_reload_on_person)
        saved = save_all_or_delete_new(family, primary_applicant)
      else
        family = person.primary_family
      end
      return family
    end

    private

    def self.initialize_person(user, name_pfx, first_name, middle_name,
                               last_name, name_sfx, ssn, dob, gender, role_type, no_ssn=nil)
        person_attrs = {
          user: user,
          name_pfx: name_pfx,
          first_name: first_name,
          middle_name: middle_name,
          last_name: last_name,
          name_sfx: name_sfx,
          ssn: ssn,
          dob: dob,
          gender: gender,
          no_ssn: no_ssn,
          role_type: role_type
        }
        result = FindOrCreateInsuredPerson.call(person_attrs)
        return result.person, result.is_new
    end

    def self.find_or_build_employee_role(person, employer_profile, census_employee, hired_on)
      roles = person.employee_roles.where(
          "employer_profile_id" => employer_profile.id.to_s,
          "hired_on" => census_employee.hired_on
        )

      role = case roles.count
      when 0
        # Assign employee-specifc attributes
        person.employee_roles.build(employer_profile: employer_profile, hired_on: hired_on)
      when 1
        roles.first
      else
        # What am I doing here?
        nil
      end
    end

    def self.initialize_family(person, dependents)
      family = person.primary_family
      family ||= Family.new
      applicant = family.primary_applicant
      applicant ||= initialize_primary_applicant(family, person)
      person.relatives.each do |related_person|
        family.add_family_member(related_person)
      end
      dependents.each do |dependent|
        initialize_dependent(family, person, dependent)
      end
      return family, applicant
    end

    def self.initialize_primary_applicant(family, person)
      family.add_family_member(person, is_primary_applicant: true) unless family.find_family_member_by_person(person)
    end

    def self.initialize_dependent(family, primary, dependent)
      person, new_person = initialize_person(nil, nil, dependent.first_name,
                                 dependent.middle_name, dependent.last_name,
                                 dependent.name_sfx, dependent.ssn,
                                 dependent.dob, dependent.gender, "employee")
      relationship = person_relationship_for(dependent.employee_relationship)
      primary.ensure_relationship_with(person, relationship)
      family.add_family_member(person) unless family.find_family_member_by_person(person)
    end

    def self.person_relationship_for(census_relationship)
      case census_relationship
      when "spouse"
        "spouse"
      when "domestic_partner"
        "life_partner"
      when "child_under_26", "child_26_and_over", "disabled_child_26_and_over"
        "child"
      end
    end

    def self.save_all_or_delete_new(*list)
      objects_to_save = list.reject {|o| !o.changed?}
      num_saved = objects_to_save.count do |o|
        begin
          o.save.tap do |save_result|
            unless save_result
              error_message = {
                :message => "Unable to save object:\n#{o.errors.to_hash.inspect}",
                :object_kind => o.class.to_s,
                :object_id => o.id.to_s
              }
              log(JSON.dump(error_message), {:severity => "error"})
            end
          end
        rescue => e
          error_message = {
            :error => {
              :message => "unable to save object in enrollment factory",
              :object_kind => o.class.to_s,
              :object_id => o.id.to_s
            }
          }
          log(JSON.dump(error_message), {:severity => 'critical'})
          raise e
        end
      end
      if num_saved < objects_to_save.count
        objects_to_save.each {|o| o.delete}
        false
      else
        true
      end
    end
  end
end
