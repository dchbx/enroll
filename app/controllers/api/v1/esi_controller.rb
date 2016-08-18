module Api
  module V1
    class EsiController < ActionController::Base
      def roster
        begin
          request_xml = request.body.read
          parsed_request = HappyMapper.parse(request_xml)

          ssn = parsed_request.request_person.identification_id
          dob = Date::strptime(parsed_request.request_person.person_birth_date, "%m/%d/%Y")
          last_name = parsed_request.request_person.person_sur_name
          @person = Person.matchable(ssn, dob, last_name).first
          raise "Person could not be found" if @person.blank?

          @start_date = Date::strptime(parsed_request.insurance_applicant_request.insurance_applicant_requested_coverage.start_date, "%Y-%m-%d")
          @end_data = Date::strptime(parsed_request.insurance_applicant_request.insurance_applicant_requested_coverage.end_date, "%Y-%m-%d")

          hbx = @person.primary_family.latest_household.enrolled_hbx_enrollments.current_year.last
          @employee_premium_amount = hbx.premium_for(hbx.subscriber) rescue 0
          @family_premium_amount = hbx.total_premium rescue 0

          render :template => 'shared/_roster.xml.builder', :layout => false, :status => :ok
        rescue Exception => e
          render :xml => "<errors><error>#{e.message}</error></errors>", :status => :unprocessable_entity
        end
      end
    end
  end
end
