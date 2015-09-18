module Forms
  class EmployeeDependent
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :id, :family_id, :is_consumer_role, :vlp_document_id
    attr_accessor :gender, :relationship
    attr_accessor :addresses, :no_dc_address, :no_dc_address_reason, :same_with_primary
    attr_writer :family
    include ::Forms::PeopleNames
    include ::Forms::ConsumerFields
    include ::Forms::SsnField
    RELATIONSHIPS = ::PersonRelationship::Relationships + ::BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS
    #include ::Forms::DateOfBirthField
    #include Validations::USDate.on(:date_of_birth)
    
    def initialize(*attributes)
      @addresses = Address.new(kind: 'home')
      @same_with_primary = true
      super
    end

    validates_presence_of :first_name, :allow_blank => nil
    validates_presence_of :last_name, :allow_blank => nil
    validates_presence_of :gender, :allow_blank => nil
    validates_presence_of :family_id, :allow_blank => nil
    validates_presence_of :dob
    validates_inclusion_of :relationship, :in => RELATIONSHIPS.uniq, :allow_blank => nil
    validate :relationship_validation
    validate :consumer_fields_validation

    attr_reader :dob

    HUMANIZED_ATTRIBUTES = { relationship: "Select Relationship Type " }

    def self.human_attribute_name(attr, options={})
      HUMANIZED_ATTRIBUTES[attr.to_sym] || super
    end

    def consumer_fields_validation
      if @is_consumer_role.to_s == "true" #only check this for consumer flow.
        if @us_citizen.nil?
          self.errors.add(:base, "Citizenship status is required")
        elsif @us_citizen == false && @eligible_immigration_status.nil?
          self.errors.add(:base, "Eligible immigration status is required")
        elsif @us_citizen == true && @naturalized_citizen.nil?
          self.errors.add(:base, "Naturalized citizen is required")
        end
        if !tribal_id.present? && @citizen_status.present? && @citizen_status == "indian_tribe_member"
          self.errors.add(:tribal_id, "is required when native american / alaskan native is selected")
        end
      end
    end

    def dob=(val)
      @dob = Date.strptime(val, "%Y-%m-%d") rescue nil
    end

    def save
      assign_citizen_status
      return false unless valid?
      existing_inactive_family_member = family.find_matching_inactive_member(self)
      if existing_inactive_family_member
        self.id = existing_inactive_family_member.id
        existing_inactive_family_member.reactivate!(self.relationship)
        existing_inactive_family_member.save!
        return true
      end
      existing_person = Person.match_existing_person(self)
      if existing_person
        assign_person_address(existing_person)
        family_member = family.relate_new_member(existing_person, self.relationship)
        family_member.family.build_consumer_role(family_member) if self.is_consumer_role == "true"
        family_member.save!
        self.id = family_member.id
        return true
      end
      person = Person.new(extract_person_params)
      assign_person_address(person)
      return false unless try_create_person(person)
      family_member = family.relate_new_member(person, self.relationship)
      family_member.family.build_consumer_role(family_member, extract_consumer_role_params) if self.is_consumer_role == "true"
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
        person.addresses << address if address.present?
      else
        current_address = person.home_address
        if addresses["address_1"].blank? and addresses["city"].blank?
          current_address.destroy if current_address.present?
          return true
        end
        if current_address.present?
          current_address.update(addresses.permit!)
        else
          person.addresses.new(addresses.permit!)
        end
      end
    rescue => e
      false
    end

    def extract_consumer_role_params
      {
        :citizen_status => @citizen_status,
        :vlp_document_id => vlp_document_id
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
      found_family_member = FamilyMember.find(family_member_id)
      has_same_address_with_primary = compare_address_with_primary(found_family_member);
      address = if has_same_address_with_primary
                  Address.new(kind: 'home')
                elsif found_family_member.person.home_address.present?
                  found_family_member.person.home_address
                else
                  Address.new(kind: 'home')
                end

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
        :tribal_id => found_family_member.tribal_id,
        :same_with_primary => has_same_address_with_primary,
        :no_dc_address => has_same_address_with_primary ? '' : found_family_member.person.no_dc_address,
        :no_dc_address_reason => has_same_address_with_primary ? '' : found_family_member.person.no_dc_address_reason,
        :addresses => address
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
      @family_member = FamilyMember.find(id)
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
      person.update_attributes(extract_person_params).tap do
        bubble_person_errors(person)
      end
    end

    def update_attributes(attr)
      assign_attributes(attr)
      assign_citizen_status
      return false unless valid?
      return false unless try_update_person(family_member.person)
      return false unless assign_person_address(family_member.person)
      family_member.family.build_consumer_role(family_member, attr["vlp_document_id"]) if attr["is_consumer_role"] == "true"
      family_member.update_relationship(relationship)
      family_member.save!
      true
    end


    def relationship_validation
      return if family.blank? or family.family_members.blank?

      relationships = Hash.new
      family.active_family_members.each{|fm| relationships[fm._id.to_s]=fm.relationship}
      relationships[self.id.to_s] = self.relationship
      if relationships.values.count{|rs| rs=='spouse' || rs=='life_partner'} > 1
        self.errors.add(:base, "can not have multiple spouse or life partner")
      end
    end
  end
end
