module Importers
  class ConversionEmployer
    include ActiveModel::Validations
    include ActiveModel::Model
    include ::Etl::ValueParsers

    # CARRIER_MAPPING = {
    #   "aetna" => "AHI",
    #   "carefirst bluecross blueshield" => "GHMSI",
    #   "kaiser permanente" => "KFMASI",
    #   "united healthcare" => "UHIC",
    #   "united health care" => "UHIC",
    #   "unitedhealthcare" => "UHIC"
    # }

    attr_converter :fein, :as => :optimistic_ssn
    attr_converter :tpa_fein, :as => :optimistic_ssn

    attr_reader :broker_npn, :primary_location_zip, :mailing_location_zip

    attr_accessor :action,
                  :dba,
                  :legal_name,
                  :primary_location_address_1,
                  :primary_location_address_2,
                  :primary_location_city,
                  :primary_location_state,
                  :primary_location_county,
                  :mailing_location_address_1,
                  :mailing_location_address_2,
                  :mailing_location_city,
                  :mailing_location_state,
                  :contact_email,
                  :contact_phone,
                  :contact_phone_extension,
                  :enrolled_employee_count,
                  :new_hire_count,
                  :broker_name,
                  :contact_first_name,
                  :contact_last_name,
                  :registered_on

    include Validations::Email

    validates :contact_email, :email => true, :allow_blank => true
    validates_presence_of :contact_first_name, :allow_blank => false
    validates_presence_of :contact_last_name, :allow_blank => false
    validates_presence_of :legal_name, :allow_blank => false
    validates_length_of :fein, is: 9

    validate :validate_new_fein
    validate :broker_exists_if_specified
    validate :validate_tpa_if_specified

    attr_reader :warnings

    # include ::Importers::ConversionEmployerCarrierValue

    def initialize(opts = {})
      super(opts)
      @warnings = ActiveModel::Errors.new(self)
    end

    def broker_npn=(val)
      @broker_npn = Maybe.new(val).strip.extract_value
    end

    def validate_tpa_if_specified
      return true if broker_npn.blank?
      return true if tpa_fein.blank?
      unless find_broker
        warnings.add(:tpa_fein, "specified, but could not find Broker")
      end
      unless find_ga
        warnings.add(:tpa_fein, "is not an existing General Agency")
        if find_broker
          found_ga = find_broker.broker_agency_profile.default_general_agency_profile
          unless found_ga
            warnings.add(:tpa_fein, "can not be assigned from broker default - broker doesn't have one")
          end
        else
          warnings.add(:tpa_fein, "can not be assigned from broker default - no broker")
        end
      end
    end

    def find_broker
      return nil if broker_npn.blank?
      BrokerRole.by_npn(broker_npn).first
    end

    def find_ga
      return nil if tpa_fein.blank?
      org = Organization.where({
                                   :fein => tpa_fein,
                                   :general_agency_profile => {"$exists" => true}
                               }).first
      return nil unless org
      org.general_agency_profile
    end

    def fein=(val)
      @fein = prepend_zeros(val.to_s.gsub('-', '').strip, 9)
    end

    def validate_new_fein
      return true if fein.blank?
      found_org = BenefitSponsors::Organizations::Organization.where(fein: fein).first
      if found_org
        if found_org.employer_profile
          errors.add(:fein, "is already taken")
        else
          warnings.add(:fein, "already exists for organization, but does not have an employer profile")
        end
      end
    end

    def broker_exists_if_specified
      return true if broker_npn.blank?
      unless BrokerRole.by_npn(broker_npn).present?
        warnings.add(:broker_npn, "does not correspond to an existing Broker")
      end
    end

    def build_primary_address
      Address.new(
          :kind => "primary",
          :address_1 => primary_location_address_1,
          :address_2 => primary_location_address_2,
          :city => primary_location_city,
          :state => primary_location_state,
          :county => primary_location_county,
          :zip => primary_location_zip
      )
    end

    def build_mailing_address
      Address.new(
          :kind => "mailing",
          :address_1 => mailing_location_address_1,
          :address_2 => mailing_location_address_2,
          :city => mailing_location_city,
          :state => mailing_location_state,
          :zip => mailing_location_zip
      )
    end

    def map_office_locations
      locations = []
      main_address = build_primary_address
      mailing_address = build_mailing_address
      main_location = OfficeLocation.new({
                                             :address => main_address,
                                             :phone => Phone.new({
                                                                     :kind => "work",
                                                                     :full_phone_number => contact_phone
                                                                 }),
                                             :is_primary => true
                                         })
      locations << main_location
      if !mailing_address.blank?
        if !mailing_address.same_address?(main_address)
          locations << OfficeLocation.new({
                                              :is_primary => false,
                                              :address => mailing_address
                                          })
        end
      end
      locations
    end

    ["primary", "mailing"].each do |item|
      class_eval(<<-RUBY_CODE)
      def #{item}_location_zip=(val)
        if val.blank?
          @#{item}_location_zip = nil
          return val
        else
          if val.strip.length == 9
            @#{item}_location_zip = val[0..4]
          else
            @#{item}_location_zip = val.strip.rjust(5, "0")
          end
        end
      end
      RUBY_CODE
    end

    def assign_brokers
      broker_agency_accounts = []
      if !broker_npn.blank?
        br = BrokerRole.by_npn(broker_npn).first
        if !br.nil?
          broker_agency_accounts << BrokerAgencyAccount.new({
                                                                start_on: Time.now,
                                                                writing_agent_id: br.id,
                                                                broker_agency_profile_id: br.broker_agency_profile_id
                                                            })
        end
      end
      broker_agency_accounts
    end

    def employer_attestation_attributes
      EmployerAttestation.new(aasm_state: "approved")
    end

    def map_poc(emp)
      person_attrs = {
          :first_name => contact_first_name,
          :last_name => contact_last_name,
          :employer_staff_roles => [
              EmployerStaffRole.new(employer_profile_id: emp.id, benefit_sponsor_employer_profile_id: emp.id, is_owner: false)
          ],
          :phones => [
              Phone.new({
                            :kind => "work",
                            :full_phone_number => contact_phone
                        })
          ]
      }
      if !contact_email.blank?
        emails = contact_email.strip.split(',')
        person_attrs[:emails] = emails.map {|email| Email.new(:kind => "work", :address => email.gsub(/\s/, ''))}
      end
      Person.create!(person_attrs)
    end

    def update_poc(emp)
      return true if contact_first_name.blank? || contact_last_name.blank?

      matching_staff_role = emp.staff_roles.detect {|staff|
        staff.first_name.match(/#{contact_first_name}/i) && staff.last_name.match(/#{contact_last_name}/i)
      }

      if emp.staff_roles.present? && matching_staff_role.blank?
        emp.staff_roles.each do |person|
          person.employer_staff_roles.where(employer_profile_id: emp.id).each {|role| role.close_role!}
        end
      end

      if matching_staff_role.present?
        matching_staff_role.phones = [
            Phone.new({
                          :kind => "work",
                          :full_phone_number => contact_phone
                      })
        ]

        if contact_email.present?
          matching_staff_role.emails = [
              Email.new(:kind => "work", :address => contact_email)
          ]
        end

        matching_staff_role.save!
      else
        map_poc(emp)
      end
    end

    def assign_general_agencies
      broker = find_broker
      return [] unless broker
      general_agency = find_ga
      unless general_agency
        general_agency = broker.broker_agency_profile.default_general_agency_profile
      end
      return [] unless general_agency
      general_agency_accounts = []
      if broker
        if general_agency
          general_agency_accounts << GeneralAgencyAccount.new(
              :start_on => Time.now,
              :general_agency_profile_id => general_agency.id,
              :broker_role_id => broker.id
          )
        end
      end
      return general_agency_accounts
    end

    def propagate_errors(org)
      org.errors.each do |attr, err|
        errors.add(attr, err)
      end
      org.office_locations.each_with_index do |office_location, idx|
        office_location.errors.each do |attr, err|
          errors.add("office_location_#{idx}_" + attr.to_s, err)
        end
      end
    end

    def prepend_zeros(number, n)
      (n - number.to_s.size).times {number.prepend('0')}
      number
    end
  end
end