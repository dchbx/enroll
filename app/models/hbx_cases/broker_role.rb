class HbxCases::BrokerRole < HbxCases::Base
  include Mongoid::History::Trackable
  # include AuditTrail

  CATEGORY_KINDS = []

  field :broker_role_id, type: BSON::ObjectId

  def initialize(*args)
    super
  end
end
