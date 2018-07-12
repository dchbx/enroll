module BenefitSponsors
  module Serializers
    class OrganizationSerializer < ActiveModel::Serializer
      attributes :legal_name, :dba, :entity_kind, :entity_kind_options
      attribute :fein, if: :is_general_organization?
      attribute :entity_kind_options

      def is_general_organization?
        object.is_a? BenefitSponsors::Organizations::GeneralOrganization
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
