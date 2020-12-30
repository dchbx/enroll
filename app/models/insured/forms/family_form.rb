# frozen_string_literal: true

module Insured
  module Forms
    class FamilyForm
      include Virtus.model

      attribute :id,              String
      attribute :is_under_ivl_oe, Boolean
      attribute :qle_kind_id,     String
      attribute :sep_id,          String
    end
  end
end
