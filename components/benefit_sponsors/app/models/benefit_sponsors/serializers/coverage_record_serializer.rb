# frozen_string_literal: true

module BenefitSponsors
  module Serializers
    class CoverageRecordSerializer < ActiveModel::Serializer
      attributes :ssn, :gender, :dob, :hired_on, :is_applying_coverage

      # provide defaults(if any needed) that were not set on Model
      def attributes(*args)
        hash = super
        unless object.persisted?
        end
        hash
      end
    end
  end
end
