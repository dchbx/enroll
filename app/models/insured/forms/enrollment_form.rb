# frozen_string_literal: true

module Insured
  module Forms
    class EnrollmentForm
      include Virtus.model

      attribute :covered_members_first_names, Array
      attribute :current_premium,             String
      attribute :effective_on,                Date
      attribute :hbx_id,                      String
      attribute :id,                          String
      attribute :should_term_or_cancel_ivl,   String
      def hbx_enrollment
        HbxEnrollment.where(id: id).first
      end

      def family
        hbx_enrollment.family
      end

      def product
        hbx_enrollment&.product
      end
    end
  end
end
