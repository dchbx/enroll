# frozen_string_literal: true

module Insured
  module Forms
    class SelfEditAPTCForm
      include Virtus.model

      attribute :enrollment, HbxEnrollment

      def self.for_view(attrs)
        service = self_edit_aptc_service(attrs[:enrollment_id])
        form_params = service.find
        new(form_params)
      end

      def self.self_edit_aptc_service(enrollment_id)
        ::Insured::Services::SelfEditAPTCService.new(enrollment_id)
      end
    end
  end
end
