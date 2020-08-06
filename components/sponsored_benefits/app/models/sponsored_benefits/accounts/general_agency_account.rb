# frozen_string_literal: true

module SponsoredBenefits
  module Accounts
    class GeneralAgencyAccount
      include Mongoid::Document
      include Mongoid::Timestamps
      include AASM
      include Acapi::Notifiers
      include ::BenefitSponsors::Concerns::Observable
      include ::BenefitSponsors::ModelEvents::GeneralAgencyAccount

      embedded_in :plan_design_organization, class_name: "SponsoredBenefits::Organizations::PlanDesignOrganization"
      embeds_many :workflow_state_transitions, as: :transitional, class_name: "::WorkflowStateTransition"

      # Begin date of relationship
      field :start_on, type: DateTime
      # End date of relationship
      field :end_on, type: DateTime
      field :updated_by, type: String
      field :general_agency_profile_id, type: BSON::ObjectId
      field :benefit_sponsrship_general_agency_profile_id, type: BSON::ObjectId
      field :aasm_state, type: Symbol, default: :active
      field :broker_role_id, type: BSON::ObjectId
      field :broker_agency_profile_id, type: BSON::ObjectId
      field :benefit_sponsrship_broker_agency_profile_id, type: BSON::ObjectId

      scope :active, ->{ where(aasm_state: :active) }
      scope :inactive, ->{ where(aasm_state: :inactive) }

      validates_presence_of :start_on
      validates_presence_of :general_agency_profile_id, :if => proc { |m| m.benefit_sponsrship_general_agency_profile_id.blank? }
      validates_presence_of :benefit_sponsrship_general_agency_profile_id, :if => proc { |m| m.general_agency_profile_id.blank? }

      before_save :notify_before_save

      add_observer ::BenefitSponsors::Observers::NoticeObserver.new, [:process_ga_account_events]

        # belongs_to general_agency_profile

      def general_agency_profile=(profile)
        raise ArgumentError, "expected GeneralAgencyProfile" unless profile.class.to_s.match(/GeneralAgencyProfile/)
        if profile.is_a?(GeneralAgencyProfile)
          self.general_agency_profile_id = profile._id
        else
          self.benefit_sponsrship_general_agency_profile_id = profile._id
        end
        @general_agency_profile = profile
      end

      def general_agency_profile
        return @general_agency_profile if defined? @general_agency_profile
        @general_agency_profile = if benefit_sponsrship_general_agency_profile_id.blank?
                                    GeneralAgencyProfile.find(self.general_agency_profile_id)
                                  else
                                    BenefitSponsors::Organizations::GeneralAgencyProfile.find(benefit_sponsrship_general_agency_profile_id)
                                  end
      end

      def broker_agency_profile=(profile)
        raise ArgumentError, "expected BrokerAgencyProfile" unless profile.class.to_s.match(/BrokerAgencyProfile/)
        if profile.is_a?(BrokerAgencyProfile)
          self.broker_agency_profile_id = profile._id
        else
          self.benefit_sponsrship_broker_agency_profile_id = profile._id
        end
        @broker_agency_profile = profile
      end

      def broker_agency_profile
        return @broker_agency_profile if defined? @broker_agency_profile
        @broker_agency_profile = if benefit_sponsrship_broker_agency_profile_id.blank?
                                   BrokerAgencyProfile.find(self.broker_agency_profile_id)
                                 else
                                   BenefitSponsors::Organizations::BrokerAgencyProfile.find(benefit_sponsrship_broker_agency_profile_id)
                                 end
      end

      def ga_name
        Rails.cache.fetch("general-agency-name-#{benefit_sponsrship_general_agency_profile_id}", expires_in: 12.hour) do
          legal_name
        end
      end

      def legal_name
        general_agency_profile.present? ? general_agency_profile.legal_name : ""
      end

      def broker_role
        broker_role_id.present? ? ::BrokerRole.find(broker_role_id) : nil
      end

      def broker_role_name
        broker_role.present? ? broker_role.person.full_name : ""
      end

      def for_broker_agency_account?(ba_account)
        return false unless broker_role_id == ba_account.writing_agent_id
        return false unless general_agency_profile.present?
        return((start_on >= ba_account.start_on) && (start_on <= ba_account.end_on)) unless ba_account.end_on.blank?
        (start_on >= ba_account.start_on)
      end


      aasm do
        state :active, initial: true
        state :inactive

        event :terminate, after: :record_transition, before: :set_termination_date do
          transitions from: :active, to: :inactive
        end
      end

      def record_transition(*_args)
        workflow_state_transitions << WorkflowStateTransition.new(
          from_state: aasm.from_state,
          to_state: aasm.to_state,
          event: aasm.current_event,
          user_id: SAVEUSER[:current_user_id]
        )
      end

      def set_termination_date
        self.end_on = TimeKeeper.datetime_of_record
      end

      class << self
        def find(id)
          pdo = SponsoredBenefits::Organizations::PlanDesignOrganization.where(
            :"general_agency_accounts._id" => BSON::ObjectId.from_string(id)
          ).first

          if pdo.present?
            pdo.general_agency_accounts.where(
              :_id => BSON::ObjectId.from_string(id)
            ).first
            end
        end
      end
    end
  end
end
