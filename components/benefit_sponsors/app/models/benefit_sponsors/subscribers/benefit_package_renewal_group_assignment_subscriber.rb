# frozen_string_literal: true

module BenefitSponsors
  module Subscribers
    class BenefitPackageRenewalGroupAssignmentSubscriber
      include Acapi::Notifiers
      include Base

      def self.worker_specification
        Acapi::Amqp::WorkerSpecification.new(
          :queue_name => "benefit_package_renewal_group_assignment_subscriber",
          :kind => :direct,
          :routing_key => "info.events.benefit_package.renew_employee_assignment"
        )
      end

      def work_with_params(_body, _delivery_info, properties)
        headers = properties.headers || {}
        stringed_payload = headers.stringify_keys
        benefit_package_id_string = stringed_payload["benefit_package_id"]
        census_employee_id_string = stringed_payload["census_employee_id"]
        effective_on_date_string = stringed_payload["effective_on_date"]

        validation = run_validations(stringed_payload)

        unless validation.success?
          notify(
            "acapi.error.events.benefit_package.renew_employee_assignment.invalid_request", {
              :return_status => "422",
              :benefit_package_id => benefit_package_id_string,
              :census_employee_id => census_employee_id_string,
              :effective_on_date => effective_on_date_string,
              :body => JSON.dump(validation.errors.to_h)
            }.merge(extract_response_params(properties))
          )
          return :ack
        end

        begin
          benefit_package_id = validation.output[:benefit_package_id]
          census_employee_id = validation.output[:census_employee_id]
          effective_on_date = validation.output[:effective_on_date]
          bp = BenefitSponsors::BenefitPackages::BenefitPackage.find(benefit_package_id)
          ce = CensusEmployee.find(census_employee_id)
          bp.renew_employee_assignment(ce, effective_on_date)
        rescue Exception => e
          notify(
            "acapi.error.events.benefit_package.renew_employee_assignment.exception", {
              :return_status => "500",
              :benefit_package_id => benefit_package_id_string,
              :census_employee_id => census_employee_id_string,
              :effective_on_date => effective_on_date_string,
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
          "acapi.info.events.benefit_package.renew_employee_assignment.renewal_executed", {
            :return_status => "200",
            :benefit_package_id => benefit_package_id_string,
            :census_employee_id => census_employee_id_string,
            :effective_on_date => effective_on_date_string
          }.merge(extract_response_params(properties))
        )
        :ack
      end

      private

      def run_validations(stringed_payload)
        param_validator = BenefitSponsors::BenefitPackages::RenewalGroupAssignments::ParameterValidator.new
        param_validation = param_validator.call(stringed_payload)
        return param_validation unless param_validation.success?

        domain_validator = BenefitSponsors::BenefitPackages::RenewalGroupAssignments::DomainValidator.new
        domain_validation = domain_validator.call(param_validation.output)
        return domain_validation unless domain_validation.success?

        param_validation
      end
    end
  end
end
