module Subscribers
  class FamilyApplicationCompleted < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      ["acapi.info.events.family.application_completed"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      stringed_key_payload = payload.stringify_keys
      xml = stringed_key_payload["body"]
      sc = ShortCircuit.on(:processing_issue) do |err|
        log(xml, {:severity => "critical", :error_message => err})
      end
      sc.and_then do |payload|
        import_from_xml(payload)
      end
      sc.call(xml)
    end

    def ecase_id_valid?(family, verified_family)
      !family.e_case_id.present? || (family.e_case_id.include? "curam_landing") || family.e_case_id == verified_family.integrated_case_id
    end

    def import_from_xml(xml)
      verified_family = Parsers::Xml::Cv::VerifiedFamilyParser.new
      verified_family.parse(xml)
      verified_primary_family_member = verified_family.family_members.detect{ |fm| fm.id == verified_family.primary_family_member_id }
      verified_dependents = verified_family.family_members.reject{ |fm| fm.id == verified_family.primary_family_member_id }
      primary_person = search_person(verified_primary_family_member)
      throw(:processing_issue, "ERROR: Failed to find primary person in xml") unless primary_person.present?
      family = primary_person.primary_family
      throw(:processing_issue, "ERROR: Failed to find primary family for users person in xml") unless family.present?
      stupid_family_id = family.id
      active_household = family.active_household
      family.save! # In case the tax household does not exist
      #        family = Family.find(stupid_family_id) # wow
      #        active_household = family.active_household
      new_person_flag = (active_household.tax_households.size == 0) ? true : false
      active_verified_household = verified_family.households.select{|h| h.integrated_case_id == verified_family.integrated_case_id}.first
      active_verified_tax_households = active_verified_household.tax_households.select{|th| th.primary_applicant_id == verified_primary_family_member.id.split('#').last}
      new_dependents = find_or_create_new_members(verified_dependents, verified_primary_family_member)
      verified_new_address = verified_primary_family_member.person.addresses.select{|adr| adr.type.split('#').last == "home" }.first
      import_home_address(primary_person, verified_new_address)
      if verified_family.broker_accounts.present?
        newest_broker = verified_family.broker_accounts.max_by{ |broker| broker.start_on}
        newest_broker_agency_account = family.broker_agency_accounts.max_by{ |baa| baa.start_on }
        if !newest_broker_agency_account.present? || newest_broker.start_on > newest_broker_agency_account.start_on
          update_broker_for_family(family, newest_broker.broker_npn)
        end
      end
      primary_person = search_person(verified_primary_family_member) #such mongoid
      family.save!
      throw(:processing_issue, "ERROR: Integrated case id does not match existing family for xml") unless ecase_id_valid?(family, verified_family)
      family.e_case_id = verified_family.integrated_case_id if family.e_case_id.blank? || (family.e_case_id.include? "curam_landing")
      begin
        active_household.build_or_update_tax_household_from_primary(verified_primary_family_member, primary_person, active_verified_household)
      rescue
        throw(:processing_issue, "Failure to update tax household")
      end
      update_vlp_for_consumer_role(primary_person.consumer_role, verified_primary_family_member)
      begin
        new_dependents.each do |p|
          new_family_member = family.relate_new_member(p[0], p[1])
          unless new_family_member.is_active?
            new_family_member.is_active = true
            new_family_member.save!
            active_household.add_household_coverage_member(new_family_member)
          end
          if active_verified_tax_households.present?
            active_verified_tax_household = active_verified_tax_households.select{|vth| vth.id == verified_primary_family_member.id.split('#').last && vth.tax_household_members.any?{|vthm| vthm.id == p[2][0]}}.first
            if active_verified_tax_household.present?
              new_tax_household_member = active_verified_tax_household.tax_household_members.select{|thm| thm.id == p[2][0]}.first
              active_household.add_tax_household_family_member(new_family_member,new_tax_household_member)
            end
          end
        end
        if active_household.latest_active_tax_household.present?
          unless active_household.latest_active_tax_household.eligibility_determinations.present?
            log("ERROR: No eligibility_determinations found for tax_household: #{xml}", {:severity => "error"})
          end
        end
      rescue
        log("ERROR: Unable to create tax household from xml: #{xml}", {:severity => "error"})
      end
      family.active_household.coverage_households.each{|ch| ch.coverage_household_members.each{|chm| chm.save! }}
      family.save!
      UserMailer.plan_shopping_initiated(primary_person).deliver_now if new_person_flag
    end

    def update_vlp_for_consumer_role(consumer_role, verified_primary_family_member )
      begin
        verified_verifications = verified_primary_family_member.verifications
        consumer_role.import
        consumer_role.pass_ssn
        consumer_role.vlp_authority = "curam"
        consumer_role.residency_determined_at = verified_primary_family_member.created_at
        consumer_role.citizen_status = verified_verifications.citizen_status.split('#').last
        consumer_role.is_state_resident = verified_verifications.is_lawfully_present
        consumer_role.is_incarcerated = verified_primary_family_member.person_demographics.is_incarcerated
        consumer_role.save!
        if consumer_role.person.user.present?
          consumer_role.person.user.ridp_by_payload!
        end
      rescue => e
        errors_list = consumer_role.errors.full_messages + [e.message] + e.backtrace
        throw(:processing_issue, "Unable to update consumer vlp: #{errors_list.join("\n")}")
      end
    end

    def import_home_address(person, verified_new_address)
      verified_address_hash = verified_new_address.to_hash
      verified_address_hash.delete(:country)
      new_address = Address.new(
        verified_address_hash
      )
      throw(:processing_issue, "ERROR: Failed to load home address from xml") unless new_address.valid?
      if person.home_address.present?
        person.home_address.delete
      end
      person.addresses << new_address
      person.save!
    end

    def find_or_create_new_members(verified_dependents, verified_primary_family_member)
      new_people = []
      if verified_dependents.present?
        verified_dependents.each do |verified_family_member|
          existing_person = search_person(verified_family_member)
          relationship = verified_primary_family_member.person_relationships.select do |pr|
            pr.object_individual_id == verified_family_member.id &&
              pr.subject_individual_id == verified_primary_family_member.id
          end.first.relationship_uri.split('#').last

          if existing_person.present?
            find_or_build_consumer_role(existing_person)
            update_vlp_for_consumer_role(existing_person.consumer_role, verified_family_member)
            new_people << [existing_person, relationship, [verified_family_member.id]]
          else
            new_member = Person.new(
              first_name: verified_family_member.person.name_first,
              last_name: verified_family_member.person.name_last,
              middle_name: verified_family_member.person.name_middle,
              name_pfx: verified_family_member.person.name_pfx,
              name_sfx: verified_family_member.person.name_sfx,
              dob: verified_family_member.person_demographics.birth_date,
              ssn: verified_family_member.person_demographics.ssn == "999999999" ? "" : verified_family_member.person_demographics.ssn ,
              gender: verified_family_member.person_demographics.sex.split('#').last
            )
            new_member.save!
            find_or_build_consumer_role(new_member)
            update_vlp_for_consumer_role(new_member.consumer_role, verified_family_member)
            verified_new_address = verified_family_member.person.addresses.select{|adr| adr.type.split('#').last == "home" }.first
            import_home_address(new_member, verified_new_address)
            new_people << [new_member, relationship, [verified_family_member.id]]
          end
        end
      end
      new_people
    end

    def update_broker_for_family(family, npn)
      broker = BrokerRole.find_by_npn(npn)
      if broker.present?
        if broker.broker_agency_profile_id.present?
          family.hire_broker_agency(broker.id)
        else
          throw(:processing_issue, "ERROR: Broker with npn: #{npn} has no broker agency profile id")
        end
      else
        throw(:processing_issue, "ERROR: Failed to match broker with npn: #{npn}")
      end
    end

    def find_or_build_consumer_role(person)
      return person.consumer_role if person.consumer_role.present?
      person.build_consumer_role(is_applicant: true)
    end

    def search_person(verified_family_member)
      ssn = verified_family_member.person_demographics.ssn
      ssn = '' if ssn == "999999999"
      dob = verified_family_member.person_demographics.birth_date
      last_name_regex = /^#{verified_family_member.person.name_last}$/i
      first_name_regex = /^#{verified_family_member.person.name_first}$/i

      if !ssn.blank?
        Person.where({
          :encrypted_ssn => Person.encrypt_ssn(ssn)
        }).first
      else
        Person.where({
          :dob => dob,
          :last_name => last_name_regex,
          :first_name => first_name_regex
        }).first
      end
    end
  end
end
