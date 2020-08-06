# frozen_string_literal: true

class HbxStaffRole
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include Mongoid::History::Trackable

  embedded_in :person

  field :hbx_profile_id, type: BSON::ObjectId
  field :benefit_sponsor_hbx_profile_id, type: BSON::ObjectId
  field :job_title, type: String, default: ""
  field :department, type: String, default: ""
  field :is_active, type: Boolean, default: true

  track_history :on => [:fields],
                :scope => :person,
                :modifier_field => :modifier,
                :modifier_field_optional => true,
                :version_field => :tracking_version,
                :track_create => true,    # track document creation, default is false
                :track_update => true,    # track document updates, default is true
                :track_destroy => true

  delegate :hbx_id, to: :person, allow_nil: true
  delegate :dob, :dob=, to: :person, allow_nil: true

  accepts_nested_attributes_for :person

  validates_presence_of :hbx_profile_id, :if => proc { |m| m.benefit_sponsor_hbx_profile_id.blank? }
  validates_presence_of :benefit_sponsor_hbx_profile_id, :if => proc { |m| m.hbx_profile_id.blank? }

  alias is_active? is_active
  #subrole is for documentation. should be redundant with permission_id
  field :subrole, type: String, default: ""
  field :permission_id, type: BSON::ObjectId
  def permission
    return nil if permission_id.blank?
    @permission ||= Permission.find(permission_id)
  end

  def self.find(id)
    return nil if id.blank?
    people = Person.where("hbx_staff_role._id" => BSON::ObjectId.from_string(id))
    people.any? ? people[0].hbx_staff_role : nil
  end

  # belongs_to Hbx
  def hbx_profile=(new_hbx_profile)
    raise ArgumentError, "expected HbxProfile" unless (new_hbx_profile.is_a? BenefitSponsors::Organizations::HbxProfile) || (new_hbx_profile.is_a? HbxProfile)
    if new_hbx_profile.is_a? BenefitSponsors::Organizations::HbxProfile
      self.benefit_sponsor_hbx_profile_id = new_hbx_profile._id
    else
      self.hbx_profile_id = new_hbx_profile._id
    end
    @hbx_profile = new_hbx_profile
  end

  def hbx_profile
    return @hbx_profile if defined? @hbx_profile
    @hbx_profile = if self.benefit_sponsor_hbx_profile_id.present?
                     BenefitSponsors::Organizations::HbxProfile.find(self.benefit_sponsor_hbx_profile_id)
                   else
                     HbxProfile.find(self.hbx_profile_id)
                   end
  end

  def parent
    person
  end

end
