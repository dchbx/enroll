# frozen_string_literal: true

module LegacyVersioningRecords
  extend ActiveSupport::Concern

  included do
    field :version, type: Integer, default: 1

    embeds_many \
      :versions,
      class_name: name,
      validate: false,
      cyclic: true,
      inverse_of: nil

    self.cyclic = true
  end
end
