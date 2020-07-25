# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module QualifyingLifeEventKind
    class Transform
      include Dry::Monads[:result, :do]

      def call(params)
        end_on = yield parse_date(params)
        qlek   = yield fetch_qlek_object(params)
        tranform_qlek(qlek, end_on)
      end

      private

      def parse_date(params)
        end_date = Date.strptime(params[:end_on], '%m/%d/%Y')
        Success(end_date)
      rescue
        Failure([params[:qle_id], "Invalid Date: #{params[:end_on]}"])
      end

      def fetch_qlek_object(params)
        qlek = ::QualifyingLifeEventKind.where(id: params[:qle_id]).first
        qlek.present? ? Success(qlek) : Failure([params[:qle_id], "Cannot find a valid qlek object with id: #{params[:qle_id]}"])
      end

      def tranform_qlek(qlek, end_on)
        if end_on >= TimeKeeper.date_of_record
          qlek.schedule_expiration!(end_on) if qlek.may_schedule_expiration?(end_on)
          message = 'expire_pending_success'
        else
          qlek.expire!(end_on) if qlek.may_expire?(end_on)
          message = 'expire_success'
        end

        Success([qlek, message])
      end
    end
  end
end
