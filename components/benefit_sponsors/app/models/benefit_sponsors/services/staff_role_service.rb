module BenefitSponsors
  module Services
    class StaffRoleService

      attr_accessor :profile_id, :profile_type, :person

      def initialize(attrs={})
        @attrs = attrs
        @profile_id = attrs[:profile_id]
      end

      def find_profile(form)
        organization = BenefitSponsors::Organizations::Organization.where("profiles._id" => BSON::ObjectId.from_string(form[:profile_id])).first
        return if organization.blank?

        if form.is_broker_agency_staff_profile?
          organization.broker_agency_profile
        elsif form.is_general_agency_staff_profile?
          organization.general_agency_profile
        else
          organization.employer_profile
        end
      end

      def add_profile_representative!(form)
        profile = find_profile(form)
        if form.is_broker_agency_staff_profile? && form.email.present?
          match_or_create_person(form)
          persist_broker_agency_staff_role!(profile)
        elsif form[:is_broker_agency_staff_profile?]
          add_broker_agency_staff_role(form[:first_name], form[:last_name], form[:dob], form[:email], profile)
        elsif form.is_general_agency_staff_profile? && form.email.present?
          match_or_create_person(form)
          persist_general_agency_staff_role!(profile)
        elsif form[:is_general_agency_staff_profile?]
          add_general_agency_staff_role(form[:first_name], form[:last_name], form[:dob], form[:email], profile)
        else
          Person.add_employer_staff_role(form[:first_name], form[:last_name], form[:dob], form[:email], profile)
        end
      end

      def deactivate_profile_representative!(form)
        profile = find_profile(form)
        if form[:is_broker_agency_staff_profile?]
          person_ids = Person.staff_for_broker(profile).map(&:id)
          return false, 'Please add another staff role before deleting this role' if invalid_person_count?(person_ids, form)
          deactivate_broker_agency_staff_role(form[:person_id], form[:profile_id])
        elsif form[:is_general_agency_staff_profile?]
          person_ids = Person.staff_for_ga(profile).map(&:id)
          return false, 'Please add another staff role before deleting this role' if invalid_person_count?(person_ids, form)
          deactivate_general_agency_staff_role(form[:person_id], form[:profile_id])
        else
          person_ids = Person.staff_for_employer(profile).map(&:id)
          return false, 'Please add another staff role before deleting this role' if invalid_person_count?(person_ids, form)
          Person.deactivate_employer_staff_role(form[:person_id], form[:profile_id])
        end
      end

      def approve_profile_representative!(form)
        person = Person.find(form[:person_id])
        role = if form[:is_broker_agency_staff_profile?]
                 person.broker_agency_staff_roles.detect{|staff| staff.agency_pending? && staff.benefit_sponsors_broker_agency_profile_id.to_s == form[:profile_id]}
               elsif form[:is_general_agency_staff_profile?]
                 person.general_agency_staff_roles.detect{|staff| staff.agency_pending? && staff.benefit_sponsors_general_agency_profile_id.to_s == form[:profile_id]}
               else
                 person.employer_staff_roles.detect{|staff| staff.is_applicant? && staff.benefit_sponsor_employer_profile_id.to_s == form[:profile_id]}
               end
        if role && role.approve && role.save!
          return true, 'Role is approved'
        else
          return false, 'Please contact HBX Admin to report this error'
        end

      end

      def match_or_create_person(form)
        matched_people = get_matched_people(form)

        return false, "too many people match the criteria provided for your identity.  Please contact HBX." if matched_people.count > 1

        if matched_people.count == 1
          mp = matched_people.first
          self.person = mp
        else
          self.person = build_person(form)
        end

        add_person_contact_info(form)
        person.save!
      end

      def get_matched_people(form)
        Person.where(first_name: regex_for(form[:first_name]),
                     last_name: regex_for(form[:last_name]),
                     dob: form[:dob])
      end

      def persist_broker_agency_staff_role!(profile)
        terminated_brokers_with_same_profile = person.broker_agency_staff_roles.detect{|role| role if role.benefit_sponsors_broker_agency_profile_id == profile.id && role.aasm_state == "broker_agency_terminated"}
        active_brokers_with_same_profile =  person.broker_agency_staff_roles.detect{|role| role if role.benefit_sponsors_broker_agency_profile_id == profile.id && role.aasm_state == "active"}
        pending_brokers_with_same_profile = person.broker_agency_staff_roles.detect{|role| role if role.benefit_sponsors_broker_agency_profile_id == profile.id && role.aasm_state == "broker_agency_pending"}

        if terminated_brokers_with_same_profile.present?
          terminated_brokers_with_same_profile.broker_agency_pending!
          return true, person
        elsif pending_brokers_with_same_profile.present?
          return false,  "your application status was in pending with this Broker Agency"
        elsif active_brokers_with_same_profile.present?
          return false,  "you are already associated with this Broker Agency"
        else
          person.broker_agency_staff_roles << ::BrokerAgencyStaffRole.new({
                                                                            broker_agency_profile: profile
                                                                          })
          person.save!
          return true, person
        end
      end

      def persist_general_agency_staff_role!(profile)
        terminated_general_agencies_with_same_profile = person.general_agency_staff_roles.detect{|role| role if role.benefit_sponsors_general_agency_profile_id == profile.id && role.aasm_state == "general_agency_terminated"}
        active_general_agencies_with_same_profile =  person.general_agency_staff_roles.detect{|role| role if role.benefit_sponsors_general_agency_profile_id == profile.id && role.aasm_state == "active"}
        pending_general_agencies_with_same_profile = person.general_agency_staff_roles.detect{|role| role if role.benefit_sponsors_general_agency_profile_id == profile.id && role.aasm_state == "general_agency_pending"}

        if terminated_general_agencies_with_same_profile.present?
          terminated_general_agencies_with_same_profile.general_agency_pending!
          return true, person
        elsif pending_general_agencies_with_same_profile.present?
          return false,  "your application status was in pending with this General Agency"
        elsif active_general_agencies_with_same_profile.present?
          return false,  "you are already associated with this General Agency"
        else
          staff_member = ::GeneralAgencyStaffRole.new({
                                                        general_agency_profile: profile,
                                                        npn: profile.general_agency_primary_staff.npn
                                                      })
          person.general_agency_staff_roles << staff_member
          staff_member.general_agency_pending!
          person.save!
          return true, person
        end
      end

      def broker_agency_search!(form)
        results = BenefitSponsors::Organizations::Organization.broker_agencies_with_matching_agency_or_broker(form[:filter_criteria].symbolize_keys!, form.is_broker_registration_page)
        if results.first.is_a?(Person)
          @filtered_broker_roles  = results.map(&:broker_role)
          @broker_agency_profiles = results.map{|broker| broker.broker_role.broker_agency_profile}.uniq
        else
          @broker_agency_profiles = results.map(&:broker_agency_profile).uniq
        end
      end

      def general_agency_search!(form)
        results = BenefitSponsors::Organizations::Organization.general_agencies_with_matching_ga(form[:filter_criteria].symbolize_keys!, form.is_general_agency_registration_page)
        if results.first.is_a?(Person)
          # @filtered_broker_roles  = results.map(&:broker_role)
          @general_agency_profiles = results.map{|ga| ga.general_agency_primary_staff.general_agency_profile}.uniq
        else
          @general_agency_profiles = results.map(&:general_agency_profile).uniq
        end
      end

      def add_broker_agency_staff_role(first_name, last_name, dob, _email, broker_agency_profile)
        person = Person.where(first_name: /^#{first_name}$/i, last_name: /^#{last_name}$/i, dob: dob)

        return false, 'Person does not exist on the Exchange' if person.count == 0
        return false, 'Person count too high, please contact HBX Admin' if person.count > 1
        return false, 'Person already has a staff role for this broker' if Person.staff_for_broker_including_pending(broker_agency_profile).include?(person.first)

        terminated_brokers_with_same_profile =  person.first.broker_agency_staff_roles.detect{|role| role if role.benefit_sponsors_broker_agency_profile_id == broker_agency_profile.id && role.aasm_state == "broker_agency_terminated"}

        if terminated_brokers_with_same_profile.present?
          terminated_brokers_with_same_profile.broker_agency_active!
        else
          broker_agency_staff_role = BrokerAgencyStaffRole.new(person: person.first, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, aasm_state: "active")
          broker_agency_staff_role.save
        end
        [true, person.first]
      end

      def add_general_agency_staff_role(first_name, last_name, dob, _email, general_agency_profile)
        person = Person.where(first_name: /^#{first_name}$/i, last_name: /^#{last_name}$/i, dob: dob)

        return false, 'Person does not exist on the Exchange' if person.count == 0
        return false, 'Person count too high, please contact HBX Admin' if person.count > 1
        return false, 'Person already has a staff role for this General Agency' if Person.staff_for_ga_including_pending(general_agency_profile).include?(person.first)

        terminated_agencies_with_same_profile =  person.first.general_agency_staff_roles.detect{ |role| role.benefit_sponsors_general_agency_profile_id == general_agency_profile.id && role.aasm_state == "general_agency_terminated" }
        if terminated_agencies_with_same_profile.present?
          terminated_agencies_with_same_profile.general_agency_active!
        else
          general_agency_staff_role = GeneralAgencyStaffRole.new(person: person.first, benefit_sponsors_general_agency_profile_id: general_agency_profile.id, aasm_state: "active", npn: general_agency_profile.general_agency_primary_staff.npn)
          general_agency_staff_role.save
        end
        [true, person.first]
      end

      def deactivate_broker_agency_staff_role(person_id, broker_agency_profile_id)
        begin
          person = Person.find(person_id)
        rescue StandardError
          return false, 'Person not found'
        end

        broker_agency_staff_role = person.broker_agency_staff_roles.detect do |role|
          (role.benefit_sponsors_broker_agency_profile_id.to_s || role.broker_agency_profile_id.to_s) == broker_agency_profile_id.to_s && role.is_open?
        end

        return false, 'No matching Broker Agency Staff role' if broker_agency_staff_role.blank?

        broker_agency_staff_role.broker_agency_terminate!
        [true, 'Broker Agency Staff Role is inactive']
      end

      def deactivate_general_agency_staff_role(person_id, general_agency_profile_id)
        begin
          person = Person.find(person_id)
        rescue StandardError
          return false, 'Person not found'
        end

        general_agency_staff_role = person.general_agency_staff_roles.detect do |role|
          (role.benefit_sponsors_general_agency_profile_id.to_s || role.general_agency_profile_id.to_s) == general_agency_profile_id.to_s && role.is_open?
        end

        return false, 'No matching General Agency Staff role' if general_agency_staff_role.blank?

        general_agency_staff_role.general_agency_terminate!
        [true, 'General Agency Staff Role is inactive']
      end

      def add_person_contact_info(form)
        person.add_work_email(form.email)
      end

      def invalid_person_count?(ids, form)
        ids.count == 1 && ids.first.to_s == form[:person_id]
      end

      def build_person(form)
        Person.new({
                     :first_name => form[:first_name].strip,
                     :last_name => form[:last_name].strip,
                     :dob => form[:dob]
                   })
      end
      def regex_for(str)
        clean_string = ::Regexp.escape(str.strip)
        /^#{clean_string}$/i
      end

    end
  end
end
