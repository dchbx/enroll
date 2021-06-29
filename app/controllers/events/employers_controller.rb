# frozen_string_literal: true

module Events
  class EmployersController < ::ApplicationController
    include Acapi::Amqp::Responder

    def resource(connection, _delivery_info, properties, _body)
      reply_to = properties.reply_to
      headers = (properties.headers || {}).stringify_keys
      employer_id = headers["employer_id"]
      plan_year_id = headers["plan_year_id"].present? ? headers["plan_year_id"].to_s : nil
      employer_org = BenefitSponsors::Organizations::Organization.employer_by_hbx_id(employer_id).first
      manual_gen = headers["manual_gen"].present? && (headers["manual_gen"] == "true" || headers["manual_gen"] == true) ? true : false
      if employer_org.nil?
        with_response_exchange(connection) do |ex|
          ex.publish(
            "",
            {
              :routing_key => reply_to,
              :headers => {
                :return_status => "404",
                :employer_id => employer_id
              }
            }
          )
        end
      else
        employer = employer_org.employer_profile
        event_payload = render_to_string "events/v2/employers/updated", :formats => ["xml"], :locals => { employer: employer, manual_gen: manual_gen, benefit_application_id: plan_year_id }
        with_response_exchange(connection) do |ex|
          ex.publish(
            event_payload,
            {
              :routing_key => reply_to,
              :headers => {
                :return_status => "200",
                :employer_id => employer_id
              }
            }
          )
        end
      end
    end
  end
end
