module Events
  class CensusEmployeesController < ::ApplicationController
    include Acapi::Amqp::Responder

    def resource(connection, delivery_info, properties, body)
      begin
        reply_to = properties.reply_to
        headers = properties.headers || {}
        census_employees=[]

        dob =  Date.parse(headers["dob"]) rescue nil
        if headers["ssn"].present? && dob.kind_of?(Date)
          census_employees = find_census_employee({ssn: headers["ssn"], dob: Date.parse(headers["dob"])})
          return_status = "200"
        end

        return_status = "404" if census_employees.empty?

        response_payload = render_to_string "events/census_employee/employer_response", :formats => ["xml"], :locals => {:census_employees => census_employees}

        reply_with(connection, reply_to, return_status, response_payload)
      rescue Exception => e
        reply_with(connection, reply_to, "500", JSON.dump({exception: e.inspect, backtrace: e.backtrace.inspect}))
      end
    end

    private

    def reply_with(connection, reply_to, return_status, body)
      headers = {:return_status => return_status}

      with_response_exchange(connection) do |ex|
        ex.publish(body, {:routing_key => reply_to, :headers => headers})
      end
    end

    def find_census_employee(options)
      (CensusEmployee.search_with_ssn_dob(options[:ssn], options[:dob]).to_a + CensusEmployee.search_dependent_with_ssn_dob(options[:ssn], options[:dob]).to_a).uniq
    end
  end
end