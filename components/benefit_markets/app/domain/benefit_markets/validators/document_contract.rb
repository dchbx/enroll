# frozen_string_literal: true

module BenefitMarkets
  module Validators
    class DocumentContract < Dry::Validation::Contract

      params do
        required(:title).filled(:string)
        required(:creator).filled(:string)
        optional(:subject).maybe(:string)
        optional(:description).maybe(:string)
        required(:publisher).filled(:string)
        optional(:contributor).maybe(:string)
        optional(:date).maybe(:string)
        required(:type).filled(:string)
        required(:format).filled(:string)
        optional(:identifier).maybe(:string)
        required(:source).filled(:string)
        required(:language).filled(:string)
        optional(:relation).maybe(:string)
        optional(:coverage).maybe(:string)
        optional(:rights).maybe(:string)
        optional(:tags).array(:hash)
        optional(:size).maybe(:string)
      end
    end
  end
end