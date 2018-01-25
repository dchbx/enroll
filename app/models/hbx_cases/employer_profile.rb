class HbxCases::EmployerProfile < HbxCases::Base
  include Mongoid::History::Trackable
  # include AuditTrail

  CATEGORY_KINDS = []

  belongs_to :employer_profile

  def initialize(*args)
    super
    self.aca_market_kind = "shop"
  end

end
