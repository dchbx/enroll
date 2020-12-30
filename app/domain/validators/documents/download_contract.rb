# frozen_string_literal: true

module Validators
  module Documents
    class DownloadContract < ::Dry::Validation::Contract

      params do
        required(:model).value(:string)
        required(:model_id).value(:string)
        required(:relation).value(:string)
        required(:relation_id).value(:string)
        optional(:content_type).value(:string)
        optional(:file_name).value(:string)
        optional(:disposition).value(:string)
      end
    end
  end
end
