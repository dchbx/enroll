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

      def work_with_params(body, delivery_info, properties)
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
          @renewal_message_properties = properties
          bp.renew_member_benefit(ce, self)
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
        ensure
          @renewal_message_properties = nil
        end

        notify(
          "acapi.info.events.benefit_package.renew_employee.renewal_executed", {
            :return_status => "200",
            :benefit_package_id => benefit_package_id_string,
            :census_employee_id => census_employee_id_string
          }.merge(extract_response_params(properties))
        )
        return :ack
      end

      def report_renewal_failure(census_employee, benefit_package, issue_string)
        notify(
          "acapi.info.events.benefit_package.renew_employee.renewal_failed", {
            :return_status => "500",
            :benefit_package_id => benefit_package.id.to_s,
            :census_employee_id => census_employee.id.to_s,
            :body => issue_string
          }.merge(extract_response_params(@renewal_message_properties))
        )
      end

      def report_enrollment_renewal_exception(hbx_enrollment, exception)
        notify(
          "acapi.info.events.benefit_package.renew_employee.renewal_enrollment_exception", {
            :return_status => "500",
            :hbx_enrollment_id => hbx_enrollment.id,
            :body => JSON.dump(
              {
                :error => exception.inspect,
                :message => exception.message,
                :backtrace => exception.backtrace
              }
            )
          }.merge(extract_response_params(@renewal_message_properties))
        )
      end

      def report_enrollment_save_renewal_failure(hbx_enrollment, model_errors)
        notify(
          "acapi.info.events.benefit_package.renew_employee.renewal_enrollment_save_failed", {
            :return_status => "500",
            :hbx_enrollment_id => hbx_enrollment.id,
            :body => JSON.dump(model_errors.to_hash)
          }.merge(extract_response_params(@renewal_message_properties))
        )
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
