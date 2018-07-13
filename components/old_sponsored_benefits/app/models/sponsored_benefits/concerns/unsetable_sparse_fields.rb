require 'active_support/concern'

module SponsoredBenefits
  extend ActiveSupport::Concern

  module Concerns::UnsetableSparseFields
    def unset_sparse(field)
      normalized = database_field_name(field)
      attributes.delete(normalized)
    end
  end
end
