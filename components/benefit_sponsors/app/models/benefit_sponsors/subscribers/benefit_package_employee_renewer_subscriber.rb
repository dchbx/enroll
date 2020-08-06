# frozen_string_literal: true

module BenefitSponsors
  module Subscribers
    class BenefitPackageEmployeeRenewerSubscriber
      include Acapi::Notifiers
      include Base

      def self.worker_specification
        Acapi::Amqp::WorkerSpecification.new(
          :queue_name => "benefit_package_employee_renewer",
          :kind => :direct,
          :routing_key => "info.events.benefit_package.renew_employee"
        )
      end

      def work_with_params(_body, _delivery_info, properties)
        headers = properties.headers || {}
        stringed_payload = headers.stringify_keys
        benefit_package_id_string = stringed_payload["benefit_package_id"]
        census_employee_id_string = stringed_payload["census_employee_id"]

        validation = run_validations(stringed_payload)

        unless validation.success?
          notify(
            "acapi.error.events.benefit_package.renew_employee.invalid_request", {
              :return_status => "422",
              :benefit_package_id => benefit_package_id_string,
              :census_employee_id => census_employee_id_string,
              :body => JSON.dump(validation.errors.to_h)
            }.merge(extract_response_params(properties))
          )
          return :ack
        end

        begin
          benefit_package_id = validation.output[:benefit_package_id]
          census_employee_id = validation.output[:census_employee_id]
          bp = BenefitSponsors::BenefitPackages::BenefitPackage.find(benefit_package_id)
          ce = CensusEmployee.find(census_employee_id)
          bp.renew_member_benefit(ce)
        rescue Exception => e
          notify(
            "acapi.error.events.benefit_package.renew_employee.exception", {
              :return_status => "500",
              :benefit_package_id => benefit_package_id_string,
              :census_employee_id => census_employee_id_string,
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
          "acapi.info.events.benefit_package.renew_employee.renewal_executed", {
            :return_status => "200",
            :benefit_package_id => benefit_package_id_string,
            :census_employee_id => census_employee_id_string
          }.merge(extract_response_params(properties))
        )
        :ack
      end

      private

      def run_validations(stringed_payload)
        param_validator = BenefitSponsors::BenefitPackages::EmployeeRenewals::ParameterValidator.new
        param_validation = param_validator.call(stringed_payload)
        return param_validation unless param_validation.success?

        domain_validator = BenefitSponsors::BenefitPackages::EmployeeRenewals::DomainValidator.new
        domain_validation = domain_validator.call(param_validation.output)
        return domain_validation unless domain_validation.success?

        param_validation
      end
    end
  end
end
