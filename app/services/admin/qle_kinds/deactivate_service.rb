# frozen_string_literal: true.

module Admin
  module QleKinds
    class DeactivateService

      include Admin::QleKinds::Injection[
        "deactivate_params_validator",
        "deactivate_domain_validator",
        "deactivate_virtual_model"
      ]

      def self.call(current_user, qle_kind_data)
        new.call(current_user, qle_kind_data)
      end

      def call(current_user, qle_kind_data)
        params_result = deactivate_params_validator.call(qle_kind_data)
        return params_result unless params_result.success?
        request = deactivate_virtual_model.new(params_result.output)
        call_with_request(current_user, request, qle_kind_data)
      end

      def call_with_request(current_user, request, qle_kind_data)
        result = deactivate_domain_validator.call(
          user: current_user,
          request: request,
          service: self
        )
        return result unless result.success?
        deactivate_record(request, qle_kind_data)
      end

      def end_on_present?(end_on)
        end_on.present?
      end

      protected

      def deactivate_record(request, qle_kind_data)
        deactivated_record = QualifyingLifeEventKind.find(qle_kind_data["_id"])
        end_on_date = Date.strptime(request.end_on, '%m/%d/%Y')
        deactivated_record.update_attributes!(end_on: end_on_date)
        # TODO: Wasn't sure if needed to create a new response
        Admin::QleKinds::ServiceResponse.new(deactivated_record)
      end
    end
  end
end