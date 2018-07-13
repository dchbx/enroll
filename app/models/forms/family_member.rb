module Forms
  class FamilyMember
    include ActiveModel::Model
    include ActiveModel::Validations
    include Config::AcaModelConcern

    attr_accessor :id, :family_id, :is_consumer_role, :is_resident_role, :vlp_document_id
    attr_accessor :gender, :relationship
    attr_accessor :addresses, :no_dc_address, :no_dc_address_reason, :same_with_primary, :is_applying_coverage
    attr_writer :family
    include ::Forms::PeopleNames
    include ::Forms::ConsumerFields
    include ::Forms::SsnField
    RELATIONSHIPS = ::PersonRelationship::Relationships + ::BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS
    #include ::Forms::DateOfBirthField
    #include Validations::USDate.on(:date_of_birth)

    def initialize(*attributes)
      @addresses = [Address.new(kind: 'home'), Address.new(kind: 'mailing')]
      @same_with_primary = "true"
      @is_applying_coverage = true
      super
    end

    validates_presence_of :first_name, :allow_blank => nil
    validates_presence_of :last_name, :allow_blank => nil
    validates_presence_of :gender, :allow_blank => nil
    validates_presence_of :family_id, :allow_blank => nil
    validates_presence_of :dob
    validates_inclusion_of :relationship, :in => RELATIONSHIPS.uniq, :allow_blank => nil, message: ""
    validate :relationship_validation
    validate :consumer_fields_validation

    attr_reader :dob

    HUMANIZED_ATTRIBUTES = { relationship: "Select Relationship Type " }

    def self.human_attribute_name(attr, options={})
      HUMANIZED_ATTRIBUTES[attr.to_sym] || super
    end

    def consumer_fields_validation
      return true unless individual_market_is_enabled?
      if (@is_consumer_role.to_s == "true" && is_applying_coverage.to_s == "true")#only check this for consumer flow.
        if @us_citizen.nil?
          self.errors.add(:base, "Citizenship status is required")
        elsif @us_citizen == false && @eligible_immigration_status.nil?
          self.errors.add(:base, "Eligible immigration status is required")
        elsif @us_citizen == true && @naturalized_citizen.nil?
          self.errors.add(:base, "Naturalized citizen is required")
        end

        if @indian_tribe_member.nil?
          self.errors.add(:base, "native american / alaskan native status is required")
        end

        if !tribal_id.present? && @indian_tribe_member
          self.errors.add(:tribal_id, "is required when native american / alaskan native is selected")
        end

        if @is_incarcerated.nil?
          self.errors.add(:base, "Incarceration status is required")
        end
      end
    end

    def dob=(val)
      @dob = Date.strptime(val, "%Y-%m-%d") rescue nil
    end

    def consumer_role=(val)
      true
    end

    def save
      assign_citizen_status
      return false unless valid?
      existing_inactive_family_member = family.find_matching_inactive_member(self)
      if existing_inactive_family_member
        self.id = existing_inactive_family_member.id
        existing_inactive_family_member.reactivate!(self.relationship)
        existing_inactive_family_member.save!
        family.save!
        return true
      end
      existing_person = Person.match_existing_person(self)
      if existing_person
        family_member = family.relate_new_member(existing_person, self.relationship)
        if self.is_consumer_role == "true"
          family_member.family.build_consumer_role(family_member)
        elsif self.is_resident_role == "true"
          family_member.build_resident_role(family_member)
        end
        assign_person_address(existing_person)
        family_member.save!
        family.save!
        self.id = family_member.id
        return true
      end
      person = Person.new(extract_person_params)
      return false unless try_create_person(person)
      family_member = family.relate_new_member(person, self.relationship)
      if self.is_consumer_role == "true"
        family_member.family.build_consumer_role(family_member, extract_consumer_role_params)
      elsif self.is_resident_role == "true"
        family_member.family.build_resident_role(family_member)
      end
      assign_person_address(person)
      family.save_relevant_coverage_households
      family.save!
      self.id = family_member.id
      true
    end

    def try_create_person(person)
      person.save.tap do
        bubble_person_errors(person)
      end
    end

    def assign_person_address(person)
      if same_with_primary == 'true'
        primary_person = family.primary_family_member.person
        person.update(no_dc_address: primary_person.no_dc_address, no_dc_address_reason: primary_person.no_dc_address_reason)
        address = primary_person.home_address
        if address.present?
          person.home_address.try(:destroy)
          person.addresses << address
          person.save
        end
      else
        home_address = person.home_address rescue nil
        mailing_address = person.has_mailing_address? ? person.mailing_address : nil

        addresses.each do |key, address|
          current_address = case address["kind"]
                            when "home"
                              home_address
                            when "mailing"
                              mailing_address
                            else
                              next
                            end
          if address["address_1"].blank? && address["city"].blank?
            current_address.destroy if current_address.present?
            next
          end
          if current_address.present?
            current_address.update(address.permit!)
          else
            person.addresses.create(address.permit!)
          end
        end
      end
      true
    rescue => e
      false
    end

    def extract_consumer_role_params
      {
        :citizen_status => @citizen_status,
        :vlp_document_id => vlp_document_id,
        :is_applying_coverage => is_applying_coverage
      }
    end

    def extract_person_params
      {
        :first_name => first_name,
        :last_name => last_name,
        :middle_name => middle_name,
        :name_pfx => name_pfx,
        :name_sfx => name_sfx,
        :gender => gender,
        :dob => dob,
        :ssn => ssn,
        :no_ssn => no_ssn,
        :race => race,
        :ethnicity => ethnicity,
        :language_code => language_code,
        :is_incarcerated => is_incarcerated,
        :citizen_status => @citizen_status,
        :tribal_id => tribal_id,
        :no_dc_address => no_dc_address,
        :no_dc_address_reason => no_dc_address_reason
      }
    end

    def persisted?
      !id.blank?
    end

    def destroy!
      family.remove_family_member(family_member.person)
      family.save!
    end

    def family
      @family ||= Family.find(family_id)
    end

    def self.find(family_member_id)
      found_family_member = ::FamilyMember.find(family_member_id)
      has_same_address_with_primary = compare_address_with_primary(found_family_member);
      home_address = if has_same_address_with_primary
                  Address.new(kind: 'home')
                else
                  found_family_member.try(:person).try(:home_address) || Address.new(kind: 'home')
                end
      mailing_address = found_family_member.person.has_mailing_address? ? found_family_member.person.mailing_address : Address.new(kind: 'mailing')
      record = self.new({
        :relationship => found_family_member.primary_relationship,
        :id => family_member_id,
        :family => found_family_member.family,
        :family_id => found_family_member.family_id,
        :first_name => found_family_member.first_name,
        :last_name => found_family_member.last_name,
        :middle_name => found_family_member.middle_name,
        :name_pfx => found_family_member.name_pfx,
        :name_sfx => found_family_member.name_sfx,
        :dob => (found_family_member.dob.is_a?(Date) ? found_family_member.dob.try(:strftime, "%Y-%m-%d") : found_family_member.dob),
        :gender => found_family_member.gender,
        :ssn => found_family_member.ssn,
        :race => found_family_member.race,
        :ethnicity => found_family_member.ethnicity,
        :language_code => found_family_member.language_code,
        :is_incarcerated => found_family_member.is_incarcerated,
        :citizen_status => found_family_member.citizen_status,
        :naturalized_citizen => found_family_member.naturalized_citizen,
        :eligible_immigration_status => found_family_member.eligible_immigration_status,
        :indian_tribe_member => found_family_member.indian_tribe_member,
        :tribal_id => found_family_member.tribal_id,
        :same_with_primary => has_same_address_with_primary.to_s,
        :no_dc_address => has_same_address_with_primary ? '' : found_family_member.try(:person).try(:no_dc_address),
        :no_dc_address_reason => has_same_address_with_primary ? '' : found_family_member.try(:person).try(:no_dc_address_reason),
        :addresses => [home_address, mailing_address]
      })
    end

    def self.compare_address_with_primary(family_member)
      current = family_member.person
      primary = family_member.family.primary_family_member.person

      compare_keys = ["address_1", "address_2", "city", "state", "zip"]
      current.no_dc_address == primary.no_dc_address &&
        current.no_dc_address_reason == primary.no_dc_address_reason &&
        current.home_address.attributes.select{|k,v| compare_keys.include? k} == primary.home_address.attributes.select{|k,v| compare_keys.include? k}
    rescue
      false
    end

    def family_member
      @family_member = ::FamilyMember.find(id)
    end

    def assign_attributes(atts)
      atts.each_pair do |k, v|
        self.send("#{k}=".to_sym, v)
      end
    end

    def bubble_person_errors(person)
      if person.errors.has_key?(:ssn)
        person.errors.get(:ssn).each do |err|
          self.errors.add(:ssn, err)
        end
      end
    end

    def try_update_person(person)
      person.consumer_role.update_attributes(:is_applying_coverage => is_applying_coverage) if person.consumer_role
      person.update_attributes(extract_person_params).tap do
        bubble_person_errors(person)
      end
    end

    def update_attributes(attr)
      assign_attributes(attr)
      assign_citizen_status
      return false unless valid?
      return false unless try_update_person(family_member.person)
      if attr["is_consumer_role"] == "true"
        family_member.family.build_consumer_role(family_member, attr["vlp_document_id"])
        return false unless assign_person_address(family_member.person)
      elsif attr["is_resident_role"] == "true"
        family_member.family.build_resident_role(family_member)
      end
      assign_person_address(family_member.person)
      family_member.update_relationship(relationship)
      family_member.save!
      true
    end


    def relationship_validation
      return if family.blank? || family.family_members.blank?

      relationships = Hash.new
      family.active_family_members.each{|fm| relationships[fm._id.to_s]=fm.relationship}
      relationships[self.id.to_s] = self.relationship
      if relationships.values.count{|rs| rs=='spouse' || rs=='life_partner'} > 1
        self.errors.add(:base, "can not have multiple spouse or life partner")
      end
    end
  end
end
