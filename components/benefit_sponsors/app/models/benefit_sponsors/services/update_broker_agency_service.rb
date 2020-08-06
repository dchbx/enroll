# frozen_string_literal: true

module BenefitSponsors
  module Services
    class UpdateBrokerAgencyService

      attr_accessor :broker_agency, :legal_name

      def initialize(options = {})
        @legal_name = options[:legal_name]
        @broker_agency = find_broker_agency(@legal_name) unless @legal_name.blank?
      end

      def update_broker_profile_id(attr = {})
        return if attr.empty? || attr[:hbx_id].nil? || broker_agency.nil?

        person = find_person(attr[:hbx_id])
        broker_staff_roles = person.broker_agency_staff_roles

        return "person not present" unless person.present?
        return 2  if broker_staff_roles.count >= 2
        return "Already Exist" if broker_staff_roles.detect { |staff_role| staff_role.benefit_sponsors_broker_agency_profile_id.to_s == broker_agency.id.to_s }

        person.broker_agency_staff_roles.first.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_agency.id)
      end

      def update_broker_assignment_date(attr = {})
        return if attr.empty?
        hbx_ids = attr[:hbx_ids]
        new_date = attr[:start_date]
        hbx_ids.each do |hbx_id|
          organization = find_organization(hbx_id)
          next unless organization.present?
          organization.employer_profile.active_broker_agency_account.update_attributes(start_on: new_date)
        end
      end

      def update_broker_agency_attributes(attr = {})
        return if attr.empty?
        broker_agency.update_attributes!(attr)
      end

      def update_organization_attributes(attr = {})
        return if attr.empty?
        broker_agency.organization.update_attributes!(attr)
      end

      def assign_broker_agency_to_employer(employer_profile_id, start_on = TimeKeeper.date_of_record)
        return if employer_profile_id.nil?
        employer_profile = find_profile(employer_profile_id)

        return unless employer_profile.present?
        # so stupid this line should go away
        employer_profile.broker_role_id = broker_agency.primary_broker_role
        employer_profile.hire_broker_agency(broker_agency, start_on)
        employer_profile.save!
        send_notification(broker_role, employer_profile)
      end

      def remove_broker_agency_to_employer(employer_profile_id, terminate_on = TimeKeeper.date_of_record)
        return if employer_profile_id.nil?
        employer_profile = find_profile(employer_profile_id)

        return unless employer_profile.present?
        employer_profile.fire_broker_agency(terminate_on)
        employer_profile.save!
      end

      def send_notification(broker_role)
        invitation = BenefitSponsors::Services::InvitationEmails.new({broker_role_id: broker_role.id, employer_profile: employer_profile})
        invitation.send_broker_successfully_associated_email
      rescue Exception => e
        puts e.inspect
        puts e.backtrace
      end

      private

      def find_broker_agency(legal_name)
        organization = BenefitSponsors::Organizations::Organization.broker_agency_profiles.where(legal_name: legal_name).first
        raise "organizational broker agency profile do not exist with fein #{legal_name}" unless organization
        organization.broker_agency_profile
      end

      def find_person(hbx_id)
        Person.by_hbx_id(hbx_id).first
      end

      def find_profile(employer_profile_id)
        BenefitSponsors::Organizations::Profile.find(employer_profile_id)
      end

      def find_organization(hbx_id)
        BenefitSponsors::Organizations::Organization.where(hbx_id: hbx_id).first
      end

    end
  end
end