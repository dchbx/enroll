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
          @url = BASE_URL + IVL_PATH
        else
          @census_employee = @hbx_enrollment.employee_role.census_employee
          @is_congress = is_congress
          @url = is_congress ? CONGRESS_URL : BASE_URL + SHOP_PATH
        end
      end

      def generate_url
        #return @url if is_congress
        return "http://checkbook_url" if Rails.env.test?

        begin
          construct_body =
            if is_congress
              construct_body_congress
            else
              @hbx_enrollment.kind.downcase == "individual" ? construct_body_ivl : construct_body_shop
            end

          @result = HTTParty.post(@url,
                :body => construct_body.to_json,
                :headers => { 'Content-Type' => 'application/json' } )
          uri =
            if @result.parsed_response.is_a?(String)
              JSON.parse(@result.parsed_response)["URL"]
            else
              @result.parsed_response["URL"]
            end
          if uri.present?
            return uri
          else
            raise "Unable to generate url"
          end
        rescue Exception => e
          Rails.logger.error { "Unable to generate url for hbx_enrollment_id #{@hbx_enrollment.id} due to #{e.backtrace}" }
          # redirects to plan shopping show page if url generation is failed.
          return "/insured/plan_shoppings/#{@hbx_enrollment.id}?market_kind=#{@hbx_enrollment.kind}&coverage_kind=#{@hbx_enrollment.coverage_kind}"
        end
      end

      def enrollment_year
        @hbx_enrollment.effective_on.year
      end

      def csr_value
        active_tax_house_hold = @hbx_enrollment.household.latest_active_tax_household_with_year(enrollment_year)
        return '-01' unless active_tax_house_hold

        csr_kind = active_tax_house_hold.valid_csr_kind(hbx_enrollment)
        '-' + EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP[csr_kind]
      end

      def aptc_value
        active_house_hold = @hbx_enrollment.household.latest_active_tax_household_with_year(enrollment_year)
        return "NULL" if active_house_hold.nil?

        active_house_hold.latest_eligibility_determination.max_aptc.to_i
      end

      def construct_body_shop
        {
          "remote_access_key": Rails.application.config.checkbook_services_remote_access_key,
          "reference_id": Rails.application.config.checkbook_services_reference_id,
          "employer_effective_date": employer_effective_date,
          "employee_coverage_date": @hbx_enrollment.effective_on.strftime("%Y-%m-%d"),
          "employer":
          {
            "state": 11,
            "county": 001
          },
          "family": build_family,
          "contribution": employer_contributions,
          "reference_plan": reference_plan.hios_id,
          "filterOption": filter_option,
          "filterValue": filter_value,
          "enrollmentId": @hbx_enrollment.id.to_s
        }
      end

      def construct_body_ivl
        {
          "remote_access_key": Rails.application.config.checkbook_services_remote_access_key,
          "reference_id": Rails.application.config.checkbook_services_reference_id,
          "enrollment_year": enrollment_year,
          "family": consumer_build_family,
          "aptc": elected_aptc.to_s,
          "csr": csr_value,
          "enrollmentId": @hbx_enrollment.id.to_s # Host Name will be static as Checkbook suports static URL's and hostname should be changed before going to production.
        }
      end

      def construct_body_congress
        {
          "remote_access_key": Rails.application.config.checkbook_services_remote_access_key,
          "reference_id": Rails.application.config.checkbook_services_reference_id,
          "employee_coverage_date": @hbx_enrollment.effective_on.strftime("%Y-%m-%d"),
          "family": build_congress_employee_age,
          "enrollmentId": @hbx_enrollment.id.to_s # Host Name will be static as Checkbook suports static URL's and hostname should be changed before going to production.
        }
      end

      def employer_effective_date
        # benefit_group_assignment  = @hbx_enrollment.effective_on < @census_employee.active_benefit_group_assignment.plan_year.end_on ? @census_employee.active_benefit_group_assignment : @census_employee.renewal_benefit_group_assignment
        # benefit_group_assignment = @census_employee.renewal_benefit_group_assignment  || @census_employee.active_benefit_group_assignment
        # benefit_group_assignment.benefit_group.plan_year.start_on.strftime("%Y-%m-%d")
        @hbx_enrollment.sponsored_benefit_package.start_on.strftime("%Y-%m-%d")
      end

      def filter_value
        case @hbx_enrollment.sponsored_benefit_package.plan_option_kind.to_s
        when "single_plan"
          # @hbx_enrollment.benefit_group.reference_plan_id.to_s
          reference_plan.hios_id.to_s
        when "single_product"
          reference_plan.hios_id.to_s
        when "metal_level"
          reference_plan.metal_level
        else
          reference_plan.carrier_profile.legal_name
        end
      end

      def filter_option
        case @hbx_enrollment.sponsored_benefit_package.plan_option_kind.to_s
        when "single_plan"
          "Plan"
        when "single_product"
          "Plan"
        when "single_carrier"
          "Carrier"
        when "single_issuer"
          "Carrier"
        when "metal_level"
          "Metal"
        end
      end

      def employer_contributions
        premium_benefit_contributions = {}
        @hbx_enrollment.sponsored_benefit_package.sorted_composite_tier_contributions.each do |relationship_benefit|
          next if ["child_26_and_over","nephew_or_niece","grandchild","child_26_and_over_with_disability"].include? relationship_benefit.display_name
          relationship = shop_relationship_benefit_hash[relationship_benefit.display_name]
          premium_benefit_contributions[relationship] = relationship_benefit.contribution_pct.to_i
        end
        premium_benefit_contributions
      end

      def shop_relationship_benefit_hash
        @shop_relationship_benefit_hash ||= {
          "Child Under 26" => "child",
          "Employee" => "employee",
          "Spouse" => "spouse",
          "Domestic Partner" => "domestic_partner"
        }
      end

      def reference_plan
        @hbx_enrollment.sponsored_benefit_package.reference_plan
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
