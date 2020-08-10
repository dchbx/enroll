# frozen_string_literal: true

require 'cgi'
require 'dry-types'

Dry::Types.load_extensions(:maybe)

module Types
  send(:include, Dry.Types())
  include Dry::Logic

  IndividualEffectiveOnKinds = Types::Coercible::String.enum(*QualifyingLifeEventKind::IVL_EFFECTIVE_ON_KINDS)

  ShopEffectiveOnKinds = Types::Coercible::String.enum(*QualifyingLifeEventKind::SHOP_EFFECTIVE_ON_KINDS)

  FehbEffectiveOnKinds = Types::Coercible::String.enum(*QualifyingLifeEventKind::FEHB_EFFECTIVE_ON_KINDS)
end

