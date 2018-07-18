module BenefitSponsors
  module Accounts
    class GeneralAgencyAccount
      include Mongoid::Document
      include SetCurrentUser
      include Mongoid::Timestamps
      include AASM

      embedded_in :benefit_sponsorship

      # Begin date of relationship
      field :start_on, type: DateTime
      # End date of relationship
      field :end_on, type: DateTime
      field :updated_by, type: String
      field :general_agency_profile_id, type: BSON::ObjectId
      field :aasm_state, type: String, default: 'active'
      field :broker_role_id, type: BSON::ObjectId

      scope :active, -> {where(aasm_state: 'active')}
      scope :inactive, -> {where(aasm_state: 'inactive')}

      validates_presence_of :start_on, :general_agency_profile_id

      #TODO based on new profile
      # belongs_to general_agency_profile
      # def general_agency_profile=(new_general_agency_profile)
      #   raise ArgumentError.new("expected GeneralAgencyProfile") unless new_general_agency_profile.is_a?(GeneralAgencyProfile)
      #   self.general_agency_profile_id = new_general_agency_profile._id
      #   @general_agency_profile = new_general_agency_profile
      # end
      #
      # def general_agency_profile
      #   return @general_agency_profile if defined? @general_agency_profile
      #   @general_agency_profile = GeneralAgencyProfile.find(self.general_agency_profile_id) unless self.general_agency_profile_id.blank?
      # end
      #
      #
      # def ga_name
      #   Rails.cache.fetch("general-agency-name-#{self.general_agency_profile_id}", expires_in: 12.hour) do
      #     legal_name
      #   end
      # end
      #
      #
      # def legal_name
      #   general_agency_profile.present? ? general_agency_profile.legal_name : ""
      # end
      #
      # def broker_role
      #   broker_role_id.present? ? BrokerRole.find(broker_role_id) : nil
      # end
      #
      # def broker_role_name
      #   broker_role.present? ? broker_role.person.full_name : ""
      # end
      #
      # def for_broker_agency_account?(ba_account)
      #   return false unless (broker_role_id == ba_account.writing_agent_id)
      #   return false unless general_agency_profile.present?
      #   if !ba_account.end_on.blank?
      #     return((start_on >= ba_account.start_on) && (start_on <= ba_account.end_on))
      #   end
      #   (start_on >= ba_account.start_on)
      # end
      #
      #
      # aasm do
      #   state :active, initial: true
      #   state :inactive
      #
      #   event :terminate do
      #     transitions from: :active, to: :inactive
      #   end
      # end
      #
      # class << self
      #   def find(id)
      #     org = Organization.unscoped.where(:"employer_profile.general_agency_accounts._id" => id).first
      #     org.employer_profile.general_agency_accounts.detect {|account| account._id == id} unless org.blank?
      #   end
      #
      #   def all
      #     orgs = Organization.exists(employer_profile: true).exists("employer_profile.general_agency_accounts" => true).to_a
      #     list = []
      #     orgs.each do |org|
      #       list.concat(org.employer_profile.general_agency_accounts) if org.employer_profile.general_agency_accounts.present?
      #     end
      #     list = list.sort {|a, b| b.start_on <=> a.start_on}
      #
      #     list
      #   end
      #
      #   def find_by_broker_role_id(broker_role_id)
      #     orgs = Organization.unscoped.where(:"employer_profile.general_agency_accounts.broker_role_id" => broker_role_id)
      #     list = []
      #     orgs.each do |org|
      #       list.concat(org.employer_profile.general_agency_accounts.where(broker_role_id: broker_role_id).entries) if org.employer_profile.general_agency_accounts.present?
      #     end
      #     list = list.sort {|a, b| b.start_on <=> a.start_on}
      #
      #     list
      #   end
      # end
    end
  end
end

