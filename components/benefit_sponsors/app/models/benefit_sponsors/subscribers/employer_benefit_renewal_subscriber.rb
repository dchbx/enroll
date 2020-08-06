# frozen_string_literal: true

module BenefitSponsors
  module Subscribers
    class EmployerBenefitRenewalSubscriber
      include Acapi::Notifiers
      include Base

      def self.worker_specification
        Acapi::Amqp::WorkerSpecification.new(
          :queue_name => "employer_benefit_renewal_subscriber",
          :kind => :direct,
          :routing_key => "info.events.benefit_sponsorship.execute_benefit_renewal"
        )
      end

      def work_with_params(_body, _delivery_info, properties)
        headers = properties.headers || {}
        stringed_payload = headers.stringify_keys
        benefit_sponsorship_id_string = stringed_payload["benefit_sponsorship_id"]
        new_date_string = stringed_payload["new_date"]

        param_validator = BenefitSponsors::BenefitSponsorships::RenewalRequests::ParameterValidator.new
        validation = param_validator.call(stringed_payload)

        unless validation.success?
          notify(
            "acapi.error.events.benefit_sponsorship.execute_benefit_renewal.invalid_request", {
              :return_status => "422",
              :benefit_sponsorship_id => benefit_sponsorship_id_string,
              :new_date => new_date_string,
              :body => JSON.dump(validation.errors.to_h)
            }.merge(extract_response_params(properties))
          )
          return :ack
        end

        benefit_sponsorship_id = validation.output[:benefit_sponsorship_id]
        new_date = validation.output[:new_date]

        benefit_sponsorship = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:id => benefit_sponsorship_id).first

        unless benefit_sponsorship
          notify(
            "acapi.error.events.benefit_sponsorship.execute_benefit_renewal.benefit_sponsorship_not_found", {
              :return_status => "404",
              :benefit_sponsorship_id => benefit_sponsorship_id_string,
              :new_date => new_date_string,
              :body => JSON.dump({
                                   "benefit sponsorship" => ["can't be found"]
                                 })
            }.merge(extract_response_params(properties))
          )
          return :ack
        end

        begin
          sponsorship_service = BenefitSponsors::BenefitSponsorships::AcaShopBenefitSponsorshipService.new(new_date: new_date)
          business_policy = business_policy_for(benefit_sponsorship, :renew_sponsor_benefit)
          sponsorship_service.execute(benefit_sponsorship, :renew_sponsor_benefit, business_policy, extract_workflow_id(properties))
        rescue Exception => e
          notify(
            "acapi.error.events.benefit_sponsorship.execute_benefit_renewal.benefit_renewal_failed", {
              :return_status => "500",
              :benefit_sponsorship_id => benefit_sponsorship_id_string,
              :new_date => new_date_string,
              :body => JSON.dump({
                                   :error => e.inspect,
                                   :message => e.message,
                                   :backtrace => e.backtrace
                                 })
            }.merge(extract_response_params(properties))
          )
          return :reject
        end
        :ack
      end

      private

      def business_policy_for(benefit_sponsorship, business_policy_name)
        BenefitSponsors::BusinessPolicies::PolicyResolver.benefit_sponsorship_policy_for(benefit_sponsorship, business_policy_name)
      end
    end
  end
end
