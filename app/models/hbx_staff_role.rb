class HbxStaffRole
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps

  embedded_in :person

  field :hbx_profile_id, type: BSON::ObjectId
  field :job_title, type: String, default: ""
  field :department, type: String, default: ""
  field :is_active, type: Boolean, default: true

  delegate :hbx_id, to: :person, allow_nil: true
  delegate :dob, :dob=, to: :person, allow_nil: true

  accepts_nested_attributes_for :person

  validates_presence_of :hbx_profile_id

  alias_method :is_active?, :is_active
  #subrole is for documentation. should be redundant with permission_id
  field :subrole, type: String, default: ""
  field :permission_id, type: BSON::ObjectId
  def permission
    Permission.find(permission_id)
  end

  def self.find(id)
    return nil if id.blank?
    people = Person.where("hbx_staff_role._id" => BSON::ObjectId.from_string(id))
    people.any? ? people[0].hbx_staff_role : nil
  end

  # belongs_to Hbx
  def hbx_profile=(new_hbx_profile)
    raise ArgumentError.new("expected HbxProfile") unless new_hbx_profile.is_a? HbxProfile
    self.hbx_profile_id = new_hbx_profile._id
    @hbx_profile = new_hbx_profile
  end

  def hbx_profile
    return @hbx_profile if defined? @hbx_profile
    @hbx_profile = HbxProfile.find(self.hbx_profile_id)
  end

  def parent
    person
  end

end
