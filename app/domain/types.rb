# frozen_string_literal: true

require 'cgi'
require 'dry-types'

Dry::Types.load_extensions(:maybe)

module Types
  send(:include, Dry.Types())
  include Dry::Logic

  individual_reasons   = QualifyingLifeEventKind.by_market_kind('individual').non_draft.map(&:reason).uniq
  IndividualQleReasons = Types::Coercible::String.enum(*individual_reasons)

  shop_reasons   = QualifyingLifeEventKind.by_market_kind('shop').non_draft.map(&:reason).uniq
  ShopQleReasons = Types::Coercible::String.enum(*shop_reasons)

  fehb_reasons   = QualifyingLifeEventKind.by_market_kind('fehb').non_draft.map(&:reason).uniq
  FehbQleReasons = Types::Coercible::String.enum(*fehb_reasons)

  IndividualEffectiveOnKinds = Types::Coercible::String.enum(*QualifyingLifeEventKind::IVL_EFFECTIVE_ON_KINDS)

  ShopEffectiveOnKinds = Types::Coercible::String.enum(*QualifyingLifeEventKind::SHOP_EFFECTIVE_ON_KINDS)

  FehbEffectiveOnKinds = Types::Coercible::String.enum(*QualifyingLifeEventKind::FEHB_EFFECTIVE_ON_KINDS)
end
