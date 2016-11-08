module Forms
  class OrganizationSignup
    include ActiveModel::Validations
    attr_accessor :id
    attr_accessor :person_id
    attr_accessor :person
    attr_accessor :legal_name, :dba, :entity_kind, :fein, :is_fake_fein
    attr_reader :dob
    attr_accessor :office_locations

    include FnameLname

    validates :fein,
      length: { is: 9, message: "%{value} is not a valid FEIN" },
      numericality: true
    validates_presence_of :dob, :if => Proc.new { |m| m.person_id.blank? }
    validates_presence_of :first_name, :if => Proc.new { |m| m.person_id.blank? }
    validates_presence_of :last_name, :if => Proc.new { |m| m.person_id.blank? }
    validates_presence_of :fein, :legal_name
    validates :entity_kind,
      inclusion: { in: ::Organization::ENTITY_KINDS, message: "%{value} is not a valid business entity kind" },
      allow_blank: false

    validate :office_location_validations
    validate :office_location_kinds
    validate :has_broker_agency, :if => Proc.new { |m| Organization
                                                         .broker_agency_profile_by_fein(m.fein).present? }

    class PersonAlreadyMatched < StandardError; end
    class TooManyMatchingPeople < StandardError; end

    def initialize(attrs = {})
      @office_locations ||= []
      assign_wrapper_attributes(attrs)
      ensure_office_locations
    end

    def assign_wrapper_attributes(attrs = {})
      attrs.each_pair do |k,v|
        self.send("#{k}=", v)
      end
    end

    def match_or_create_person(current_user)
      if !self.person_id.blank?
        self.person = Person.find(self.person_id)
        return
      end
      new_person =   Person.new({
        :first_name => first_name,
        :last_name => last_name,
        :dob => dob
      })
      if  self.class.to_s == 'Forms::EmployerProfile'
        matched_people = Person.where(
          first_name: regex_for(first_name),
          last_name: regex_for(last_name),
          dob: new_person.dob
          )
      else
        matched_people = Person.where(
          first_name: regex_for(first_name),
          last_name: regex_for(last_name),
          # TODO
          # dob: new_person.dob
        )
      end
      if matched_people.count > 1
        raise TooManyMatchingPeople.new
      end
      if matched_people.count == 1
        mp = matched_people.first
        if mp.user.present?
          if mp.user.id.to_s != current_user.id
            raise PersonAlreadyMatched.new
          end
        end
        self.person = mp
      else
        self.person = new_person
      end
    end

    def to_key
      @id
    end

    def ensure_office_locations
      if @office_locations.empty?
        new_office_location = OfficeLocation.new
        new_office_location.build_address
        new_office_location.build_phone
        @office_locations = [new_office_location]
      end
    end

    def office_location_validations
      @office_locations.each_with_index do |ol, idx|
        ol.valid?
        ol.errors.each do |k, v|
          self.errors.add("office_locations_attributes.#{idx}.#{k}", v)
        end
      end
    end

    def office_location_kinds
      location_kinds = self.office_locations.flat_map(&:address).flat_map(&:kind)
      #too_many_of_a_kind = location_kinds.group_by(&:to_s).any? { |k, v| v.length > 1 }

      #if too_many_of_a_kind
      #  self.errors.add(:base, "may not have more than one of the same kind of address")
      #end

      if location_kinds.count('primary').zero?
        self.errors.add(:base, "must select one primary address")
      elsif location_kinds.count('primary') > 1
        self.errors.add(:base, "can't have multiple primary addresses")
      elsif location_kinds.count('mailing') > 1
        self.errors.add(:base, "can't have more than one mailing address")
      end
    end

    def has_broker_agency
      self.errors.add(:base, "fein is already in use.")
    end

    def office_locations_attributes
      @office_locations.map do |office_location|
        office_location.attributes
      end
    end

    def office_locations_attributes=(attrs)
      @office_locations = []
      attrs.each_pair do |k, att_set|
        att_set.delete('phone_attributes') if att_set["phone_attributes"].present? && att_set["phone_attributes"]["number"].blank?
        @office_locations << OfficeLocation.new(att_set)
      end
      @office_locations
    end

    def dob=(val)
      @dob = Date.strptime(val,"%Y-%m-%d") rescue nil
    end
    
    # Strip non-numeric characters
    def fein=(new_fein)
      @fein =  new_fein.to_s.gsub(/\D/, '') rescue nil
    end

    def regex_for(str)
      #Regexp.compile(Regexp.escape(str.to_s))
      clean_string = Regexp.escape(str.strip)
      /^#{clean_string}$/i
    end
  end
end
