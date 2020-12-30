# frozen_string_literal: true

module Insured
  module Forms
    class SbcDocumentForm
      include Virtus.model

      attribute :id,                    String
      attribute :identifier,            String
    end
  end
end
