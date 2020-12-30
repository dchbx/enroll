# frozen_string_literal: true

module Insured
  module Forms
    class ProductForm
      include Virtus.model

      attribute :id,                    String
      attribute :application_period,    Date
      attribute :kind,                  Symbol
      attribute :title,                 String
      attribute :hios_id,               String
      attribute :issuer_profile_id,     String
      attribute :display_carrier_logo, String
      attribute :active_year,           Date
      attribute :metal_level_kind,      String
      attribute :nationwide,            Boolean
      attribute :sbc_document,          ::Insured::Forms::SbcDocumentForm
    end
  end
end
