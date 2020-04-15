# frozen_string_literal: true

require 'dry/monads'

module HbxEnrollments
  module Operations
    class FindModel
      include Dry::Monads[:result, :do]
      extend Dry::Monads[:maybe, :result]

      def call(params)
        hbx_enrollment = yield hbx_enrollment(params)

        Success(hbx_enrollment)
      end

      private

      def hbx_enrollment(params)
        hbx_enrollment = HbxEnrollment.where(id: params[:enrollment_id].strip)
        if hbx_enrollment.present?
          Success(hbx_enrollment.first)
        else
          Failure("enrollment not found hbx_id:#{params[:enrollment_id].strip}")
        end
      end
    end
  end
end