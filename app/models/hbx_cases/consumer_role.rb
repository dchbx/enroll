class HbxCases::ConsumerRole < HbxCases::Base
  include Mongoid::History::Trackable
  # include AuditTrail

  CATEGORY_KINDS = ["application", "enrollments", "household", "citizenship status", "financial", 
                    "qualifying life events", "notices", "documents"]

  field :qle_id, type: BSON::ObjectId
  field :consumer_role_id, type: BSON::ObjectId

  belongs_to :family

  def initialize(*args)
    super
    self.aca_market_kind = "individual"
  end


end
