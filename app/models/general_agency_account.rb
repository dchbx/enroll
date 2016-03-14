class GeneralAgencyAccount
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include AASM

  embedded_in :employer_profile

  # Begin date of relationship
  field :start_on, type: DateTime
  # End date of relationship
  field :end_on, type: DateTime
  field :updated_by, type: String
  field :general_agency_profile_id, type: BSON::ObjectId
  field :aasm_state, type: String, default: 'active'

  validates_presence_of :start_on, :general_agency_profile_id

  # belongs_to general_agency_profile
  def general_agency_profile=(new_general_agency_profile)
    raise ArgumentError.new("expected GeneralAgencyProfile") unless new_general_agency_profile.is_a?(GeneralAgencyProfile)
    self.general_agency_profile_id = new_general_agency_profile._id
    @general_agency_profile = new_general_agency_profile
  end

  def general_agency_profile
    return @general_agency_profile if defined? @general_agency_profile
    @general_agency_profile = GeneralAgencyProfile.find(self.general_agency_profile_id) unless self.general_agency_profile_id.blank?
  end

  def legal_name
    general_agency_profile.present? ? general_agency_profile.legal_name : ""
  end

  aasm do
    state :active, initial: true
    state :inactive

    event :terminate do
      transitions from: :active, to: :inactive
    end
  end

  class << self
    def find(id)
      org = Organization.unscoped.where(:"employer_profile.general_agency_accounts._id" => id).first
      org.employer_profile.general_agency_accounts.detect { |account| account._id == id } unless org.blank?
    end
  end
end
