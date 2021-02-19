require 'date'
module BenefitSponsors
  module Organizations
    module Factories
      class ProfileFactory
        include BenefitSponsors::RegistrationHelper
        include ActiveModel::Validations
        include BenefitSponsors::Forms::NpnField

        attr_accessor :profile_id, :profile_type, :organization, :profile, :current_user, :claimed, :pending, :coverage_record,
                      :first_name, :last_name, :email, :dob, :npn, :fein, :legal_name, :person, :market_kind,
                      :area_code, :number, :extension, :handler

        cattr_accessor :profile_type

        delegate :is_employer_profile?, :is_broker_profile?, :is_general_agency_profile?, to: :class

        def self.call(attributes)
          factory_obj = new(attributes.merge({
            handler: initialize_handler(attributes[:profile_type])
          }))
          factory_obj.current_user = current_user(attributes[:current_user_id])
          factory_obj.profile_id.present? ? update!(factory_obj, attributes) : persist!(factory_obj, attributes)
        end

        def self.update!(factory_obj, attributes)
          organization = factory_obj.get_organization
          organization.assign_attributes(sanitize_organization_params_for_update(attributes[:organization]))
          organization.update_benefit_sponsorship(organization.employer_profile) if (is_employer_profile? && address_changed?(organization.employer_profile))
          factory_obj.update_representative(attributes[:staff_roles_attributes][0]) if attributes[:staff_roles_attributes].present?
          updated = if organization.valid?
            organization.save!
            update_plan_design_organization(organization)
          else
            factory_obj.errors.add(:organization, organization.errors.full_messages)
            false
          end
          return factory_obj
        end

        def self.update_plan_design_organization(organization)
          return unless is_employer_profile?
          plan_design_organization = ::SponsoredBenefits::Organizations::PlanDesignOrganization.where(sponsor_profile_id: organization.employer_profile.id, has_active_broker_relationship: true).first
          return if plan_design_organization.blank?
          plan_design_organization.update_attributes!(legal_name: organization.legal_name, dba: organization.dba)
        end

        def update_representative(attributes)
          handler.update_representative(attributes)

          if is_broker_profile?
            person = Person.find(attributes[:person_id])
            person.update_attributes!(attributes.slice(:first_name, :last_name, :dob))
          end
        end

        def self.persist!(factory_obj, attributes)
          factory_obj.save(attributes[:organization])
        end

        def self.build(attrs)
          new(attrs.merge({
            handler: initialize_handler(attrs[:profile_type])
          })).build_organization
        end

        def self.initialize_handler(type)
          "#{self}::#{type.camelize}".constantize.new
        end

        def initialize(attrs)
          self.profile_type = attrs[:profile_type]
          self.profile_id = attrs[:profile_id]
          self.handler = attrs[:handler]
          initialize_attributes(attrs)
        end

        def initialize_attributes(attrs)
          initialize_staff_role_attributes(staff_role_attributes(attrs[:staff_roles_attributes])) # Always one while creating
          initialize_agency_attributes(attrs[:organization])
        end

        def initialize_staff_role_attributes(attrs)
          if attrs.present?
            if attrs[:person_id].blank?
              self.first_name = attrs[:first_name]
              self.last_name = attrs[:last_name]
              self.email = attrs[:email]
              self.dob = attrs[:dob]
              self.npn = attrs[:npn]
              self.area_code = attrs[:area_code]
              self.number = attrs[:number]
              self.extension = attrs[:extension]
            else
              initialize_staff_role_from_person(attrs[:person_id])
            end
            self.coverage_record = attrs[:coverage_record] if attrs[:coverage_record].present?
          end
        end

        def initialize_agency_attributes(attrs)
          if attrs.present?
            self.fein = attrs[:fein]
            self.legal_name = attrs[:legal_name]
          end
        end

        def initialize_staff_role_from_person(person_id)
          person = get_person(person_id)
          self.first_name = person.first_name
          self.last_name = person.last_name
          self.dob = person.dob
        end

        def self.address_changed?(profile)
          address = profile.primary_office_location.address
          address.changed_attributes.include?("zip") || address.changed_attributes.include?("county") || address.changed_attributes.include?("state")
        end

        def save(attributes)
          return self unless match_or_create_person
          existing_org = get_existing_organization unless is_broker_profile?
          return self if organization_validity_failed?(existing_org)
          self.organization = init_profile_organization(existing_org, attributes)
          return self if broker_agency_profile_validity_failed?
          unless self.valid?
            errors.add(:organization, self.errors.full_messages.join(', '))
            return self
          end
          return self unless persist_agency!
          self
        end

        def persist_agency!
          if organization.valid?
            # benefitsponsorships are being saved and had to save manually.
            organization.benefit_sponsorships.each do |benefit_sponsorship|
              benefit_sponsorship.save! if benefit_sponsorship.new_record?
            end
            organization.save!
            persist_representative!
          else
            errors.add(:organization, organization.errors.full_messages)
            return false
          end
          return true
        end

        def persist_representative!
          handler.organization = organization
          handler.factory = self
          handler.person = person
          handler.current_user = current_user
          handler.persist_representative!
        end

        def init_profile_organization(existing_org, attributes)
          handler.organization = existing_org
          handler.factory = self
          handler.fetch_organization(attributes) || build_organization(attributes)
        end

        def build_organization(attrs = {})
          if profile_id.blank?
            self.organization = build_organization_class.new(organization_attributes(attrs))
            self.organization.profiles << build_profile(profile_attributes(attrs))
            self.profile.add_benefit_sponsorship if is_employer_profile?
            self.organization
          else
            get_organization
          end
        end

        def build_profile(attrs = {})
          profile = handler.build_profile(attrs)
          profile.office_locations << build_office_locations if profile.office_locations.empty?
          self.profile_id = profile.id
          self.profile = profile
        end

        def build_office_locations
          new_office_location = Locations::OfficeLocation.new
          new_office_location.build_address
          new_office_location.build_phone
          new_office_location
        end

        def build_organization_class
          is_broker_profile? ? ExemptOrganization : GeneralOrganization
        end

        def build_person
          Person.new({
            :first_name => first_name.strip,
            :last_name => last_name.strip,
            :dob => dob
          })
        end

        def organization_attributes(attrs = {})
          attrs.except(:profiles_attributes).merge({
            site: site,
            fein: (fein.present? ? fein.strip : nil),
            legal_name: (legal_name.present? ? legal_name.strip : nil)
          })
        end

        def profile_attributes(attrs={})
          attrs[:profiles_attributes][0] if attrs[:profiles_attributes].present?
        end

        def staff_role_attributes(attrs={})
          attrs.present? ? attrs[0] : attrs
        end

        def self.sanitize_organization_params_for_update(attrs={})
          attrs[:profiles_attributes][0].except!(:referred_by, :referred_reason)
          attrs
        end

        def match_or_create_person
          matched_people = get_matched_people

          if matched_people.count > 1
            errors.add(:staff_role, "too many people match the criteria provided for your identity.  Please contact HBX.")
            return false
          end

          if matched_people.count == 1
            mp = matched_people.first
            if is_employer_profile? && mp.user.present?
              if mp.user.id.to_s != current_user.id.to_s
                errors.add(:staff_role, "a person matching the provided personal information has already been claimed by another user.  Please contact HBX.")
                return false
              end
            end
            self.person = mp
          else
            self.person = build_person
          end

          add_person_contact_info
          person.save!
        end

        def organization_validity_failed?(org)
          issuer_requesting_sponsor_benefits?(org) || broker_profile_already_registered?(org) || person.errors.present?
        end

        def broker_profile_already_registered?(organization)
          if is_broker_profile? && organization.present? && organization.broker_agency_profile.present?
            errors.add(:organization, "has already been created for this Agency type")
            return true
          end
          return false
        end

        def issuer_requesting_sponsor_benefits?(organization)
          if organization.present? && organization.is_an_issuer_profile?
            errors.add(:organization, "Issuer cannot sponsor benefits")
            return true
          end
        end

        def redirection_url(is_pending=nil, is_saved=nil)
          handler.is_saved = is_saved
          handler.factory = self
          handler.redirection_url
        end

        def redirection_url_on_update
          handler.profile_id = profile_id
          handler.redirection_url_on_update
        end

        def get_organization
          self.organization = BenefitSponsors::Organizations::Organization.where(:"profiles._id" => BSON::ObjectId.from_string(profile_id)).first
        end

        def get_profile
          self.profile = BenefitSponsors::Organizations::Profile.find(profile_id)
        end

        BenefitSponsor = Struct.new(:factory, :organization, :profile, :person, :profile_id, :current_user, :is_saved) do

          def persist_representative!
            profile = organization.employer_profile
            person.user = current_user
            employer_ids = person.employer_staff_roles.where(:aasm_state.ne => :is_closed).map(&:benefit_sponsor_employer_profile_id)
            if employer_ids.include? profile.id
              pending = false
            else
              pending = organization && Person.staff_for_employer(profile).detect{|person|person.user_id}
              role_state = pending ? 'is_applicant' : 'is_active'
              attrs = {
                person: person,
                :benefit_sponsor_employer_profile_id => profile.id,
                is_owner: true,
                aasm_state: role_state
              }
              if factory.coverage_record.present?
                coverage_record = factory.coverage_record
                address = coverage_record[:address]
                email = coverage_record[:email]
                attrs.merge!({coverage_record: {ssn: coverage_record[:ssn],
                                                gender: coverage_record[:gender],
                                                dob: coverage_record[:dob],
                                                hired_on: coverage_record[:hired_on],
                                                is_applying_coverage: coverage_record[:is_applying_coverage],
                                                address: Address.new({kind: address[:kind],
                                                                      address_1: address[:kind],
                                                                      address_2: address[:address_2],
                                                                      city: address[:city],
                                                                      county: address[:county],
                                                                      state: address[:state],
                                                                      zip: address[:zip]}),
                                                email: Email.new({kind: email[:kind],
                                                                  address: email[:address]})}})
              end
              person.employer_staff_roles << EmployerStaffRole.new(attrs)
            end

            factory.pending = pending
            current_user.roles << "employer_staff" unless current_user.roles.include?("employer_staff")
            current_user.save!
            person.save!
            approve_employer_staff_role
          end

          def approve_employer_staff_role
            role = person.employer_staff_roles.where(benefit_sponsor_employer_profile_id: factory.profile_id.to_s, aasm_state: :is_active).last
            role&.approve!
          end

          def fetch_organization(attributes)
            if organization.present?
              factory.claimed = is_employer_profile_claimed?
              unless factory.claimed
                if organization.employer_profile.blank?
                  organization.profiles << build_profile(attributes)
                  factory.profile.add_benefit_sponsorship
                end
              end
              organization
            end
          end

          def build_profile(attrs={})
            build_sponsor_profile_class.new(attrs)
          end

          def build_sponsor_profile_class
            # TODO - Use Configuration settings
            site_key = BenefitSponsors::ApplicationController::current_site.site_key
            return Organizations::AcaShopDcEmployerProfile if site_key == :dc
            return Organizations::AcaShopCcaEmployerProfile if site_key == :cca
          end

          def find_representatives
            Person.where(:employer_staff_roles => {
              '$elemMatch' => {
                :benefit_sponsor_employer_profile_id => BSON::ObjectId(profile_id),
                :aasm_state.ne => :is_closed
              }
            })
          end

          def update_representative(attributes)
            nil # Representative Info not updatable for benefit sponsor
          end

          def add_person_contact_info
            factory.person.contact_info(factory.email, factory.area_code, factory.number, factory.extension) if factory.email
          end

          def is_employer_profile_claimed?
            if organization.employer_profile.present?
              if (Person.where({"employer_staff_roles.benefit_sponsor_employer_profile_id" => organization.employer_profile._id}).any?)
                return true
              end
            end
          end

          def redirection_url
            return "sponsor_show_pending_registration_url" if factory.pending
            organization = factory.organization
            resource_id = factory.profile_id || (organization.employer_profile.id if organization.present?)
            return "sponsor_home_registration_url@#{resource_id}" if is_saved
            :sponsor_new_registration_url
          end

          def redirection_url_on_update
            :agency_edit_registration_url
          end
        end

        GeneralAgency = Struct.new(:factory, :organization, :profile, :person, :profile_id, :current_user, :is_saved) do

          def persist_representative!
            profile = organization.general_agency_profile
            person.general_agency_staff_roles << ::GeneralAgencyStaffRole.new({
              :npn => factory.npn,
              :benefit_sponsors_general_agency_profile_id => profile.id,
              :is_primary => true
            })
            profile.office_locations.each do |office_location|
              person.phones.push(Phone.new(office_location.phone.attributes.except("_id")))
            end
            person.save!
          end

          def fetch_organization(attributes)
            if organization.present? && !organization.general_agency_profile.present?
              organization.profiles << build_profile(attributes)
              organization
            end
          end

          def build_profile(attrs={})
            Organizations::GeneralAgencyProfile.new(attrs)
          end

          def find_representatives
            Person.where(:"general_agency_staff_roles" => {
              '$elemMatch' => {
                :benefit_sponsors_general_agency_profile_id => BSON::ObjectId(profile_id),
                :is_primary => true
              }
            })
          end

          def update_representative(attributes)
            person = Person.find(attributes[:person_id])
            person.update_attributes!(attributes.slice(:first_name, :last_name, :dob))
          end

          def add_person_contact_info
            factory.person.add_work_email(factory.email)
          end

          def redirection_url
            :general_agency_new_registration_url
          end

          def redirection_url_on_update
            "general_show_registration_url@#{profile_id}"
          end
        end

        BrokerAgency = Struct.new(:factory, :organization, :profile, :person, :profile_id, :current_user, :is_saved) do

          def persist_representative!
            profile = organization.broker_agency_profile
            person.broker_role = ::BrokerRole.new({
              :provider_kind => 'broker',
              :npn => factory.npn,
              :benefit_sponsors_broker_agency_profile_id => profile.id,
              :market_kind => factory.market_kind
            })

            profile.office_locations.each do  |office_location|
              person.phones.push(Phone.new(office_location.phone.attributes.except("_id")))
            end
            person.save!
            profile.update_attributes!(primary_broker_role_id: person.broker_role.id)
            trigger_broker_application_confirmation_email(person)
          end

          def fetch_organization(attributes)
            if organization.present? && !organization.broker_agency_profile.present?
              organization.profiles << build_profile(attributes)
              organization
            end
          end

          def build_profile(attrs={})
            Organizations::BrokerAgencyProfile.new(attrs)
          end

          def find_representatives
            Person.where(:"broker_role.benefit_sponsors_broker_agency_profile_id" => BSON::ObjectId.from_string(profile_id))
          end

          def update_representative(attributes)
            person = Person.find(attributes[:person_id])
            person.update_attributes!(attributes.slice(:first_name, :last_name, :dob))
          end

          def add_person_contact_info
            factory.person.add_work_email(factory.email)
          end

          def trigger_broker_application_confirmation_email(person)
            ::UserMailer.broker_application_confirmation(person).deliver_now
          end

          def redirection_url
            :broker_new_registration_url
          end

          def redirection_url_on_update
            "broker_show_registration_url@#{profile_id}"
          end
        end

        protected

        def site
          return @site if defined? @site
          @site = BenefitSponsors::ApplicationController::current_site
        end

        def site_key
          site.site_key
        end

        def self.is_broker_profile?
          profile_type == "broker_agency"
        end

        def self.is_employer_profile?
          profile_type == "benefit_sponsor"
        end

        def self.is_general_agency_profile?
          profile_type == "general_agency"
        end

        def add_person_contact_info
          handler.factory = self
          handler.add_person_contact_info
        end

        def self.current_user(user_id)
          if user_id.present?
            User.find(user_id)
          end
        end

        def self.get_profile_type(profile_id)
          organization = new({profile_id: profile_id}).get_organization
          type = organization.profiles.where(id: profile_id).first.class.to_s
          if type.match(/EmployerProfile/)
            "benefit_sponsor"
          elsif type.match(/BrokerAgencyProfile/)
            "broker_agency"
          elsif type.match(/GeneralAgencyProfile/)
            "general_agency"
          end
        end

        def self.find_representatives(profile_id, profile_type)
          return [Person.new] if profile_id.blank?
          self.profile_type = profile_type
          handler = initialize_handler(profile_type)
          handler.profile_id = profile_id
          handler.find_representatives
        end

        private

        def get_existing_organization
          return unless fein.present?
          Organization.where(:fein => fein).first
        end

        def get_matched_people
          if is_employer_profile? || is_broker_profile?
            Person.where(
              first_name: regex_for(first_name),
              last_name: regex_for(last_name),
              dob: dob
              )
          else
            Person.where(
              first_name: regex_for(first_name),
              last_name: regex_for(last_name)
            )
          end
        end

        def get_person(person_id)
          Person.find(person_id)
        end

        def regex_for(str)
          clean_string = ::Regexp.escape(str.strip)
          /^#{clean_string}$/i
        end

        def broker_agency_profile_validity_failed?
          npn_already_taken?(npn) || !valid_office_location_kinds?
        end

        def npn_already_taken?(npn)
          if is_broker_profile?
            if Person.where("broker_role.npn" => npn).any?
              errors.add(:organization, l10n("broker_agencies.profiles.npn_taken_error"))
              return true
            end
          end
          return false
        end

        def valid_office_location_kinds?
          location_groups = organization.profiles.map(&:office_locations)
          location_groups.each do |locations|
            location_kinds = locations.flat_map(&:address).flat_map(&:kind)
            if location_kinds.count('primary').zero?
              self.errors.add(:office_locations, "must select one primary address")
              return false
            elsif location_kinds.count('primary') > 1
              self.errors.add(:office_locations, "can't have multiple primary addresses")
              return false
            elsif location_kinds.count('mailing') > 1
              self.errors.add(:office_locations, "can't have more than one mailing address")
              return false
            end
          end
          return true
        end
      end
    end
  end
end
