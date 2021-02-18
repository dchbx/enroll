# frozen_string_literal: true

module BenefitSponsors
  module Subscribers
    # This class reinstates assignment in async workflow.
    class BenefitPackageReinstateGroupAssignmentSubscriber
      include Acapi::Notifiers
      include Base

      def self.worker_specification
        Acapi::Amqp::WorkerSpecification.new(
          :queue_name => "benefit_package_reinstate_group_assignment_subscriber",
          :kind => :direct,
          :routing_key => "info.events.benefit_package.reinstate_employee_assignment"
        )
      end

      def work_with_params(_body, _delivery_info, properties)
        headers = properties.headers || {}
        stringed_payload = headers.stringify_keys
        benefit_package_id_string = stringed_payload["benefit_package_id"]
        census_employee_id_string = stringed_payload["census_employee_id"]
        benefit_group_assignment_id_string = stringed_payload["benefit_group_assignment_id"]

        validation = run_validations(stringed_payload)

        unless validation.success?
          notify(
            "acapi.error.events.benefit_package.reinstate_employee_assignment.invalid_request",
            {
              :return_status => "422",
              :benefit_package_id => benefit_package_id_string,
              :census_employee_id => census_employee_id_string,
              :benefit_group_assignment_id => benefit_group_assignment_id_string,
              :body => JSON.dump(validation.errors.to_h)
            }.merge(extract_response_params(properties))
          )
          return :ack
        end

        begin
          raise StandardError, "assignment: #{benefit_group_assignment.id}" unless perform_reinstatment(validation).success?
        rescue StandardError => e
          notify(
            "acapi.error.events.benefit_package.reinstate_employee_assignment.exception",
            {
              :return_status => "500",
              :benefit_package_id => benefit_package_id_string,
              :census_employee_id => census_employee_id_string,
              :benefit_group_assignment_id => benefit_group_assignment_id_string,
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
          "acapi.info.events.benefit_package.reinstate_employee_assignment.reinstate_executed",
          {
            :return_status => "200",
            :benefit_package_id => benefit_package_id_string,
            :census_employee_id => census_employee_id_string,
            :benefit_group_assignment_id => benefit_group_assignment_id_string
          }.merge(extract_response_params(properties))
        )
        :ack
      end

      private

      def perform_reinstatment(validation)
        benefit_package_id = validation.output[:benefit_package_id]
        census_employee_id = validation.output[:census_employee_id]
        benefit_group_assignment_id = validation.output[:benefit_group_assignment_id]
        bp = BenefitSponsors::BenefitPackages::BenefitPackage.find(benefit_package_id)
        ce = CensusEmployee.find(census_employee_id)
        benefit_group_assignment = ce.benefit_group_assignments.find(benefit_group_assignment_id)
        bp.reinstate_benefit_group_assignment(benefit_group_assignment)
      end

      def run_validations(stringed_payload)
        param_validator = BenefitSponsors::BenefitPackages::ReinstateGroupAssignments::ParameterValidator.new
        param_validation = param_validator.call(stringed_payload)
        return param_validation unless param_validation.success?

        domain_validator = BenefitSponsors::BenefitPackages::ReinstateGroupAssignments::DomainValidator.new
        domain_validation = domain_validator.call(param_validation.output)
        return domain_validation unless domain_validation.success?

        param_validation
      end
    end
  end
end
