# frozen_string_literal: true

require 'cgi'
require 'dry-types'

Dry::Types.load_extensions(:maybe)

module Types
  send(:include, Dry.Types())
  include Dry::Logic

  individual_reasons   = QualifyingLifeEventKind.individual_market_events.map(&:reason).uniq
  IndividualQleReasons = Types::Coercible::String.enum(*individual_reasons)
  
  shop_reasons   = QualifyingLifeEventKind.shop_market_events.map(&:reason).uniq
  ShopQleReasons = Types::Coercible::String.enum(*shop_reasons)
    
  fehb_reasons   = QualifyingLifeEventKind.fehb_market_events.map(&:reason).uniq
  FehbQleReasons = Types::Coercible::String.enum(*fehb_reasons)
end