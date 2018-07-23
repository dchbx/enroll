module BenefitSponsors
  module Forms
    class BrokerCandidate < ::Forms::PersonSignup
      include ActiveModel::Validations
      include Validations::Email

      include ::Forms::PeopleNames
      include ::Forms::NpnField

      attr_accessor :broker_agency_id, :broker_applicant_type
      attr_accessor :market_kind, :languages_spoken, :working_hours, :accept_new_clients
      attr_accessor :addresses

      validate :validate_broker_agency
      validate :validate_duplicate_npn, :if => Proc.new {|p| p.broker_applicant_type != 'staff'}

      validates :npn, 
        length: { maximum: 10, message: "%{value} is not a valid NPN" },
        format: { with: /\A[1-9][0-9]+\z/, message: "%{value} is not a valid NPN" },
        numericality: true,
        :if => Proc.new {|p| p.broker_applicant_type != 'staff'}

      validates :email, :email => true, :allow_blank => false
      
      validates_format_of :email, :with => /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/, message: "%{value} is not valid"

      def initialize(*attributes)
        @addresses ||= []
        ensure_addresses
        super
      end

      def save
        return false unless valid?

        begin
          match_or_create_person
          person.save!
    
        rescue TooManyMatchingPeople
          errors.add(:base, "too many people match the criteria provided for your identity.  Please contact HBX-Customer Service - Call (855) 532-5465.")
          return false      
        end

        broker_agency_profile = Organizations::BrokerAgencyProfile.find(self.broker_agency_id)
        if broker_role?
          person.broker_role = ::BrokerRole.new( { 
              :provider_kind => 'broker', 
              :npn => self.npn, 
              :broker_agency_profile => broker_agency_profile,
              :market_kind => market_kind,
              :languages_spoken => languages_spoken,
              :working_hours => working_hours,
              :accept_new_clients => accept_new_clients
              })
        else
          person.broker_agency_staff_roles << ::BrokerAgencyStaffRole.new(:broker_agency_profile => broker_agency_profile)
        end

        true
      end

      def match_or_create_person
        super
        person.addresses << @addresses.select(&:valid?)
      end

      def validate_broker_agency
        if self.broker_agency_id.blank?
          errors.add(:base, "Please select your broker agency.")
        elsif ::BrokerAgencyProfile.find(self.broker_agency_id).blank?
          errors.add(:base, "Unable to locate the broker agnecy. Please contact HBX.")
        end
      end

      def validate_duplicate_npn
        if Person.where("broker_role.npn" => npn).any?
          errors.add(:base, "NPN has already been claimed by another broker. Please contact HBX.")
        end
      end

      def broker_role?
        self.broker_applicant_type == 'staff' ? false : true
      end

      def ensure_addresses
        if @addresses.empty?
          @addresses = [Address.new(kind: 'home')]
        end
      end

      def addresses_attributes
        @addresses.map do |address|
          address.attributes
        end
      end

      def addresses_attributes=(attrs)
        @addresses = []
        attrs.each_pair do |k, att_set|
          @addresses << Address.new(att_set)
        end
        @addresses
      end
    end
  end
end
