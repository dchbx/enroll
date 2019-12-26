# frozen_string_literal: true

module Insured
  module Forms
    class SelfTermOrCancelForm
      include ActiveModel::Validations
      include Virtus.model

      attribute :carrier_logo,          String
      attribute :enrollment,            ::Insured::Forms::EnrollmentForm
      attribute :family,                ::Insured::Forms::FamilyForm
      attribute :is_aptc_eligible,      Boolean
      attribute :market_kind,           String
      attribute :product,               ::Insured::Forms::ProductForm
      attribute :term_date,             Date
      attribute :elected_aptc_pct,      String

      validates :market_kind,           presence: true

      def self.for_view(attrs)
        service     = self_term_or_cancel_service(attrs)
        form_params = service.find
        new(form_params)
      end

      def self.for_post(attrs)
        service = self_term_or_cancel_service(attrs)
        service.term_or_cancel
      end

      def self.for_aptc_update_post(attrs)
        service = self_term_or_cancel_service(attrs)
        service.update_aptc
      end

      def self.self_term_or_cancel_service(attrs)
        ::Insured::Services::SelfTermOrCancelService.new(attrs)
      end

      def product
        hbx_enrollment.product
      end

      def hbx_enrollment
        enrollment&.hbx_enrollment
      end

      def special_enrollment_period
        hbx_enrollment.special_enrollment_period
      end
    end
  end
end
