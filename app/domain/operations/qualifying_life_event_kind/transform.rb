# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module QualifyingLifeEventKind
    class Transform
      include Dry::Monads[:result, :do]

      def call(params:)
        qlek   = yield fetch_qlek_object(params)
        end_on = yield parse_date(qlek, params)
        yield validate_dates(qlek, end_on)
        tranform_qlek(qlek, end_on)
      end

      private

      def fetch_qlek_object(params)
        qlek = ::QualifyingLifeEventKind.where(id: params[:qle_id]).first
        qlek.present? ? Success(qlek) : Failure([params[:qle_id], "Cannot find a valid qlek object with id: #{params[:qle_id]}"])
      end

      def parse_date(qlek, params)
        end_date = params[:end_on].to_date
        end_date.is_a?(Date) ? Success(end_date) : Failure([qlek, "Invalid Date: #{params[:end_on]}"])
      rescue
        Failure([qlek, "Invalid Date: #{params[:end_on]}"])
      end

      def validate_dates(qlek, end_on)
        if qlek.start_on.nil?
          Failure([qlek, 'Start on cannot be empty'])
        elsif qlek.start_on > end_on
          Failure([qlek, "End on: #{end_on} must be after start on date"])
        else
          Success('')
        end
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
