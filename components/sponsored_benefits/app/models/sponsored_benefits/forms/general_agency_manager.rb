# frozen_string_literal: true

module SponsoredBenefits
  module Forms
    class GeneralAgencyManager
      include ActiveModel::Validations
      include Virtus.model

      attribute :general_agency_profile_id, String
      attribute :broker_agency_profile_id, String
      attribute :plan_design_organization_id, String
      attribute :plan_design_organization_ids, Array

      attribute :action_id


      def self.for_assign(attrs = {})
        new(attrs)
      end

      def self.for_fire(attrs = {})
        new(attrs)
      end

      def self.for_index(attrs = {})
        new(attrs)
      end

      def self.for_default(attrs = {})
        new(attrs)
      end

      def self.for_clear(attrs = {})
        new(attrs)
      end

      def assign
        service.assign_general_agency
        return false if self.errors.present?
        true
      end

      def fire!
        service.fire_general_agency
        return false if self.errors.present?
        true
      end

      def set_default!
        service.set_default_general_agency
        return false if self.errors.present?
        true
      end

      def clear_default!
        service.clear_default_general_agency
        return false if self.errors.present?
        true
      end

      def service
        return @service if defined? @service
        @service = SponsoredBenefits::Services::GeneralAgencyManager.new(self)
      end
    end
  end
end
