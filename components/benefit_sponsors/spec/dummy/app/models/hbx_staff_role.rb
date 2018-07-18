class HbxStaffRole
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :person

  field :hbx_profile_id, type: BSON::ObjectId
  field :job_title, type: String, default: ""
  field :department, type: String, default: ""
  field :is_active, type: Boolean, default: true

  validates_presence_of :hbx_profile_id

  delegate :hbx_id, to: :person, allow_nil: true
  delegate :dob, :dob=, to: :person, allow_nil: true

  accepts_nested_attributes_for :person

  alias_method :is_active?, :is_active
  #subrole is for documentation. should be redundant with permission_id
  field :subrole, type: String, default: ""
  field :permission_id, type: BSON::ObjectId

  def permission
  end
end
