# frozen_string_literal: true

module BenefitSponsors
  module Serializers
    class OrganizationSerializer < ActiveModel::Serializer
      attributes :legal_name, :dba, :entity_kind, :entity_kind_options
      attribute :fein, if: :is_non_exempt_benefit_sponsor?
      attribute :entity_kind_options

      def is_non_exempt_benefit_sponsor?
        is_general_organization? || is_congress? || is_embassy_or_gov_sponsor?
      end

      def is_general_organization?
        object.is_a? BenefitSponsors::Organizations::GeneralOrganization
      end

      def is_congress?
        object.is_a_fehb_profile?
      end

      def is_embassy_or_gov_sponsor?
        object.is_embassy_or_gov_profile?
      end

      def entity_kind_options
        object.entity_kinds
      end

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
