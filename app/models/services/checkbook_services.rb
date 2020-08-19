require 'nokogiri'

module Services
  module CheckbookServices
    class PlanComparision

      attr_accessor :hbx_enrollment, :is_congress, :elected_aptc

      BASE_URL = Rails.application.config.checkbook_services_base_url
      CONGRESS_URL = Rails.application.config.checkbook_services_congress_url
      IVL_PATH = Rails.application.config.checkbook_services_ivl_path
      SHOP_PATH = Rails.application.config.checkbook_services_shop_path

      def initialize(hbx_enrollment, is_congress=false)
        @hbx_enrollment = hbx_enrollment
        if @hbx_enrollment.kind.downcase == "individual"
          @person = @hbx_enrollment.consumer_role.person
          @url = BASE_URL+IVL_PATH
        else
          @census_employee = @hbx_enrollment.employee_role.census_employee
          @is_congress = is_congress
          is_congress ? @url = CONGRESS_URL : @url = BASE_URL+SHOP_PATH
        end
      end

      def generate_url
        #return @url if is_congress
        return "http://checkbook_url" if Rails.env.test?
        begin
          construct_body = {}
          if is_congress
            construct_body = construct_body_congress
          else
            construct_body = @hbx_enrollment.kind.downcase == "individual" ? construct_body_ivl : construct_body_shop 
          end

          @result = HTTParty.post(@url,
                :body => construct_body.to_json,
                :headers => { 'Content-Type' => 'application/json' } )
          uri=""
          if @result.parsed_response.is_a?(String)
            uri = JSON.parse(@result.parsed_response)["URL"]
          else
            uri = @result.parsed_response["URL"]
          end
          if uri.present?
            return uri
          else
            raise "Unable to generate url"
            return false
          end
        rescue Exception => e
          Rails.logger.error { "Unable to generate url for hbx_enrollment_id #{@hbx_enrollment.id} due to #{e.backtrace}" }
          return false
        end
      end

      def enrollment_year
        @hbx_enrollment.effective_on.year
      end

      #Revisit this code to check the functionailty for multiple THH cases
      def csr_value
        active_tax_households = @hbx_enrollment.household.latest_active_tax_households_with_year(enrollment_year)
        active_tax_household = active_tax_households.first if active_tax_households.present?

        if active_tax_household
          case active_tax_household.valid_csr_kind(hbx_enrollment)
          when 'csr_100'
            '-01'
          when 'csr_94'
            '-06'
          when 'csr_87'
            '-05'
          when 'csr_73'
            '-04'
          when 'csr_0'
            '-02'
          when 'limited'
            '-03'
          end
        else
          return '-01'
        end
      end

      #Revisit this code to check the functionailty for multiple THH cases
      def aptc_value
        active_tax_households = @hbx_enrollment.household.latest_active_tax_households_with_year(enrollment_year)
        if active_tax_households.nil?
          return "NULL"
        else
          active_tax_households.latest_eligibility_determination.max_aptc.to_i
        end
      end

      def construct_body_shop
        {
          "remote_access_key":  Rails.application.config.checkbook_services_remote_access_key,
          "reference_id": Rails.application.config.checkbook_services_reference_id,
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
          "filterValue": filter_value,
          "enrollmentId": @hbx_enrollment.id.to_s,
        }
      end

      def construct_body_ivl
        {
          "remote_access_key":  Rails.application.config.checkbook_services_remote_access_key,
          "reference_id": Rails.application.config.checkbook_services_reference_id,
          "enrollment_year": 2019,
          "family": consumer_build_family,
          "aptc": elected_aptc.to_s,
          "csr": csr_value,
          "enrollmentId": @hbx_enrollment.id.to_s, #Host Name will be static as Checkbook suports static URL's and hostname should be changed before going to production.
         }
      end

      def construct_body_congress
        {
          "remote_access_key": Rails.application.config.checkbook_services_remote_access_key,
          "reference_id": Rails.application.config.checkbook_services_reference_id,
          "employee_coverage_date": @hbx_enrollment.effective_on.strftime("%Y-%m-%d"),
          "family": build_congress_employee_age,
          "enrollmentId": @hbx_enrollment.id.to_s, #Host Name will be static as Checkbook suports static URL's and hostname should be changed before going to production.
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

      def consumer_build_family
        family = []
        today = @hbx_enrollment.effective_on
        tribal_id = @hbx_enrollment.consumer_role.person.tribal_id.present?
        @hbx_enrollment.hbx_enrollment_members.each do |member|
          age = member.family_member.person.age_on(today)
          family << {"age": age, "pregnant": false, "AIAN": tribal_id}
        end
        family
      end

      def build_congress_employee_age
        family = []
        @hbx_enrollment.hbx_enrollment_members.each do |dependent|
          family << {"dob": dependent.family_member.person.dob.strftime("%Y-%m-%d")}
          end
          family
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
