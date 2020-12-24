# frozen_string_literal: true

module Admin
  # Result of bulk notice action
  class BulkNoticeResult
    include Mongoid::Document
    include Mongoid::Timestamps

    field :audience_id, type: String
    field :result, type: String

    embedded_in :bulk_notice
  end
end
