module ConfigurableModel
  class Service
    include Mongoid::Document
    include Mongoid::Timestamps

    field :label,       type: String # fill using key like i18n in the form if not provided
    field :description, type: String

    field :key,         type: String  #benefit_markets.shop_market.initial_application
    field :value,       type: Boolean
    field :default,     type: String

    field :path,    type: String # /BenefitMarkets::Engine
    field :is_required, type: Boolean, default: false
    field :enabled,  type: Boolean

  end
end