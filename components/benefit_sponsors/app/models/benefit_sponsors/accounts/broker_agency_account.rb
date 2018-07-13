module BenefitSponsors
  module Accounts
    class BrokerAgencyAccount
      include Mongoid::Document
      include SetCurrentUser
      include Mongoid::Timestamps
      include ::BenefitSponsors::Concerns::Observable
      include ::BenefitSponsors::ModelEvents::BrokerAgencyAccount

      embedded_in :benefit_sponsorship,
                class_name: "::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"

      embedded_in :family

      # Begin date of relationship
      field :start_on, type: DateTime

      # End date of relationship
      field :end_on, type: DateTime
      field :updated_by, type: String

      # Broker agency representing ER
      field :benefit_sponsors_broker_agency_profile_id, type: BSON::ObjectId

      # Broker writing_agent credited for enrollment and transmitted on 834
      field :writing_agent_id, type: BSON::ObjectId
      field :is_active, type: Boolean, default: true

      validates_presence_of :start_on, :benefit_sponsors_broker_agency_profile_id, :is_active

      default_scope -> {where(:is_active => true)}

      before_create :notify_observers
      after_update  :notify_observers
      after_save    :notify_on_save

      add_observer ::BenefitSponsors::Observers::BrokerAgencyAccountObserver.new, [:broker_fired?, :broker_hired?, :notifications_send]

      # belongs_to broker_agency_profile
      def broker_agency_profile=(new_broker_agency_profile)
        raise ArgumentError.new("expected BrokerAgencyProfile") unless new_broker_agency_profile.is_a?(BenefitSponsors::Organizations::BrokerAgencyProfile)
        self.benefit_sponsors_broker_agency_profile_id = new_broker_agency_profile._id
        @broker_agency_profile = new_broker_agency_profile
      end

      def broker_agency_profile
        return @broker_agency_profile if defined? @broker_agency_profile
        @broker_agency_profile = BenefitSponsors::Organizations::BrokerAgencyProfile.find(self.benefit_sponsors_broker_agency_profile_id) unless self.benefit_sponsors_broker_agency_profile_id.blank?
      end

      def ba_name
        Rails.cache.fetch("broker-agency-name-#{self.benefit_sponsors_broker_agency_profile_id}", expires_in: 12.hour) do
          legal_name
        end
      end

      def legal_name
        broker_agency_profile.present? ? broker_agency_profile.legal_name : ""
      end

      #TODO based on new organization and profile
      def writing_agent=(new_writing_agent)
        raise ArgumentError.new("expected BrokerRole") unless new_writing_agent.is_a?(BrokerRole)
        self.writing_agent_id = new_writing_agent._id
        @writing_agent = new_writing_agent
      end

      def writing_agent
        return @writing_agent if defined? @writing_agent
        @writing_agent = BrokerRole.find(writing_agent_id)
      end

      # class << self
      #   def find(id)
      #     org = Organization.unscoped.where(:"employer_profile.broker_agency_accounts._id" => id).first
      #     org.employer_profile.broker_agency_accounts.detect { |account| account._id == id } unless org.blank?
      #   end
      # end
    end
  end
end
