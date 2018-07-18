module Events
  class EmployersController < ::ApplicationController
    include Acapi::Amqp::Responder

    def resource(connection, delivery_info, properties, body)
      reply_to = properties.reply_to
      headers = (properties.headers || {}).stringify_keys
      employer_id = headers["employer_id"]
      employer_org = BenefitSponsors::Organizations::Organization.employer_by_hbx_id(employer_id).first
      manual_gen = headers["manual_gen"].present? && (headers["manual_gen"] == "true" || headers["manual_gen"] == true) ? true : false
      if !employer_org.nil?
        employer = employer_org.employer_profile
        event_payload = render_to_string "events/v2/employers/updated", :formats => ["xml"], :locals => { employer: employer, manual_gen: manual_gen }
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
      else
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
      end
    end
  end
end
