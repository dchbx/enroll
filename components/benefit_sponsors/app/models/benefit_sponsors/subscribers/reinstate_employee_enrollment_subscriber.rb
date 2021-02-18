# frozen_string_literal: true

module BenefitSponsors
  module Subscribers
    # This class reinstates enrollment in async workflow.
    class ReinstateEmployeeEnrollmentSubscriber
      include Acapi::Notifiers
      include Base

      def self.worker_specification
        Acapi::Amqp::WorkerSpecification.new(
          :queue_name => "benefit_package_reinstate_employee_enrollment_subscriber",
          :kind => :direct,
          :routing_key => "info.events.benefit_package.reinstate_employee_enrollment"
        )
      end

      def work_with_params(_body, _delivery_info, properties)
        headers = properties.headers || {}
        stringed_payload = headers.stringify_keys
        stringed_payload["notify"] = (stringed_payload["notify"] == true || stringed_payload["notify"] == "true") ? true : false

        benefit_package_id_string = stringed_payload["benefit_package_id"]
        hbx_enrollment_id_string = stringed_payload["hbx_enrollment_id"]
        notify_bool = stringed_payload["notify"]

        validation = run_validations(stringed_payload)

        unless validation.success?
          notify(
            "acapi.error.events.benefit_package.reinstate_employee_enrollment.invalid_request",
            {
              :return_status => "422",
              :benefit_package_id => benefit_package_id_string,
              :hbx_enrollment_id => hbx_enrollment_id_string,
              :notify => notify_bool,
              :body => JSON.dump(validation.errors.to_h)
            }.merge(extract_response_params(properties))
          )
          return :ack
        end

        begin
          raise StandardError, "enrollment: #{hbx_enrollment.hbx_id}" unless perform_reinstatment(validation).success?
        rescue StandardError => e
          notify(
            "acapi.error.events.benefit_package.reinstate_employee_enrollment.exception",
            {
              :return_status => "500",
              :benefit_package_id => benefit_package_id_string,
              :hbx_enrollment_id => hbx_enrollment_id_string,
              :notify => notify_bool,
              :body => JSON.dump({
                                   :error => e.inspect,
                                   :message => e.message,
                                   :backtrace => e.backtrace
                                 })
            }.merge(extract_response_params(properties))
          )
          return :reject
        end
        notify(
          "acapi.info.events.benefit_package.reinstate_employee_enrollment.reinstate_executed",
          {
            :return_status => "200",
            :benefit_package_id => benefit_package_id_string,
            :hbx_enrollment_id => hbx_enrollment_id_string,
            :notify => notify_bool
          }.merge(extract_response_params(properties))
        )
        :ack
      end

      private

      def perform_reinstatment(validation)
        benefit_package_id = validation.output[:benefit_package_id]
        hbx_enrollment_id = validation.output[:hbx_enrollment_id]
        notify = validation.output[:notify]
        bp = BenefitSponsors::BenefitPackages::BenefitPackage.find(benefit_package_id)
        hbx = HbxEnrollment.find(hbx_enrollment_id)
        bp.reinstate_enrollment(hbx, notify: notify)
      end

      def run_validations(stringed_payload)
        param_validator = BenefitSponsors::BenefitPackages::ReinstateEmployeeEnrollments::ParameterValidator.new
        param_validation = param_validator.call(stringed_payload)
        return param_validation unless param_validation.success?

        domain_validator = BenefitSponsors::BenefitPackages::ReinstateEmployeeEnrollments::DomainValidator.new
        domain_validation = domain_validator.call(param_validation.output)
        return domain_validation unless domain_validation.success?

        param_validation
      end
    end
  end
end
