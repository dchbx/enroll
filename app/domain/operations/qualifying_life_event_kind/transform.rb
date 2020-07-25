# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module QualifyingLifeEventKind
    class Transform
      include Dry::Monads[:result, :do]

      def call(params)
        qlek = yield fetch_qlek_object(params)
        tranform_qlek(qlek)
      end

      private

      def fetch_qlek_object(params)
        Success(::QualifyingLifeEventKind.find(params[:qle_id]))
      end

      def tranform_qlek(qlek)
        qlek.expire! if qlek&.may_expire?
        Success(qlek)
      end
    end
  end
end
