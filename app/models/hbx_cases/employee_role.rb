class HbxCases::EmployeeRole
  include Mongoid::History::Trackable
  # include AuditTrail

  CATEGORY_KINDS = ["application", "enrollments", "household", "qualifying life events", "notices", "documents"]

  field :qle_id, type: BSON::ObjectId
  field :employee_role_id, type: BSON::ObjectId

  belongs_to :family

  def initialize(*args)
    super
    self.aca_market_kind = "shop"
  end
end
