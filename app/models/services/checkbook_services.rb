require 'nokogiri'

module Services
  module CheckbookServices
    class PlanComparision

      attr_accessor :hbx_enrollment,:is_congress

      BASE_URL =   Rails.application.config.checkbook_services_base_url
      CONGRESS_URL = Settings.checkbook_services.congress_url

      def initialize(hbx_enrollment, is_congress=false)
        @hbx_enrollment = hbx_enrollment
        @census_employee = @hbx_enrollment.employee_role.census_employee
        @is_congress = is_congress
        is_congress ? @url = CONGRESS_URL : @url = BASE_URL+"/shop/dc/api/"
      end

      def generate_url
        return @url if is_congress
        return Settings.checkbook_services.congress_url if Rails.env.test?
        begin
          @result = HTTParty.post(@url,
                :body => construct_body.to_json,
                :headers => { 'Content-Type' => 'application/json' } )
          uri = @result.parsed_response["URL"]
          if uri.present?
            return uri
          else
            raise "Unable to generate url"
          end
        rescue Exception => e
          Rails.logger.error { "Unable to generate url for #{@census_employee.full_name} due to #{e.backtrace}" }
        end
      end

      private
      def construct_body
      {
        "remote_access_key":  Rails.application.config.checkbook_services_remote_access_key,
        "reference_id": Settings.checkbook_services.reference_id,
        "employer_effective_date": employer_effective_date,
        "employee_coverage_date": @hbx_enrollment.effective_on.strftime("%Y-%m-%d"),
        "employer": {
          "state": 11,
          "county": 001
        },
        "family": build_family,
        "contribution": employer_contributions,
        "reference_plan": reference_plan.hios_id,
        "filterOption": filter_option,
        "filterValue": filter_value
      }
      end

      def employer_effective_date
        benefit_group_assignment  = @hbx_enrollment.effective_on < @census_employee.active_benefit_group_assignment.plan_year.end_on ? @census_employee.active_benefit_group_assignment : @census_employee.renewal_benefit_group_assignment
        # benefit_group_assignment = @census_employee.renewal_benefit_group_assignment  || @census_employee.active_benefit_group_assignment
        benefit_group_assignment.benefit_group.plan_year.start_on.strftime("%Y-%m-%d")
      end

      def filter_value
        case @hbx_enrollment.benefit_group.plan_option_kind
        when "single_plan"
          # binding.pry
          # @hbx_enrollment.benefit_group.reference_plan_id.to_s
          @hbx_enrollment.benefit_group.reference_plan.hios_id.to_s
        when "metal_level"
          reference_plan.metal_level
        else
          reference_plan.carrier_profile.legal_name
        end
      end


      def filter_option
        case @hbx_enrollment.benefit_group.plan_option_kind
        when "single_plan"
          "Plan"
        when "single_carrier"
          "Carrier"
        when "metal_level"
          "Metal"
        end
      end

      def employer_contributions
        premium_benefit_contributions = {}
        @hbx_enrollment.benefit_group.relationship_benefits.each do |relationship_benefit|
          next if ["child_26_and_over","nephew_or_niece","grandchild","child_26_and_over_with_disability"].include? relationship_benefit.relationship
          relationship =  relationship_benefit.relationship == "child_under_26" ? "child" : relationship_benefit.relationship
          premium_benefit_contributions[relationship] = relationship_benefit.premium_pct.to_i
        end
        premium_benefit_contributions
      end

      def reference_plan
        @hbx_enrollment.benefit_group.reference_plan
      end

      def build_family
        family = []
        # family = [{'dob': @census_employee.dob.strftime("%Y-%m-%d") ,'relationship': 'self'}]
        # @census_employee.census_dependents.each do |dependent|
          @hbx_enrollment.hbx_enrollment_members.each do |dependent|
          next if dependent.primary_relationship == "nephew_or_niece"
          family << {'dob': dependent.family_member.person.dob.strftime("%Y-%m-%d") ,'relationship': dependent.primary_relationship}
        end
        family
      end
    end
  end
end
