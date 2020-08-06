# frozen_string_literal: true

module Importers::Mhc
  class ConversionEmployerPlanYearSet
    def headers
      common_headers = [
        "Action",
        "FEIN",
        "Doing Business As",
        "Legal Name",
        "Issuer Assigned Employer ID",
        "SIC code",
        "Physical Address 1",
        "Physical Address 2",
        "City",
        "County",
        "County FIPS code",
        "State",
        "Zip",
        "Mailing Address 1",
        "Mailing Address 2",
        "City",
        "State",
        "Zip",
        "Contact First Name",
        "Contact Last Name",
        "Contact Email",
        "Contact Phone",
        "Contact Phone Extension",
        "Enrolled Employee Count",
        "New Hire Coverage Policy",
        "Contact Address 1",
        "Contact Address 2",
        "City",
        "State",
        "Zip",
        "Broker Name",
        "Broker NPN",
        "TPA Name",
        "TPA FEIN",
        "Coverage Start Date",
        "Carrier Selected",
        "Plan Selection Category",
        "Plan Name",
        "Plan HIOS Id"
     ]

       # different headers for health and dental
      @sponsored_benefit_kind ||= :health
      sponsored_headers = @sponsored_benefit_kind == :dental ? dental_benefit_headers : health_benefit_headers

      combined_headers = (common_headers.push sponsored_headers).flatten!

      combined_headers
    end

    def health_benefit_headers
      [
          "Employee Only Rating Tier Contribution",
          "Employee Rating Tier Premium",
          "Employee And Spouse Rating Tier Offered",
          "Employee And Spouse Rating Tier Contribution",
          "Employee And Spouse Rating Tier Premium",
          "Employee And Dependents Rating Tier Offered",
          "Employee And Dependents Rating Tier Contribution",
          "Employee And Dependents Rating Tier Premium",
          "Family Rating Tier",
          "Family Rating Tier Contribution",
          "Family Rating Tier Premium",
          "Import Status",
          "Import Details"
      ]
    end

    def dental_benefit_headers
      [
          "Employer Contribution - Employee",
          "Employer Contribution - Spouse",
          "Employer Contribution - Domestic Partner",
          "Employer Contribution - Child Under 26",
          "Import Status",
          "Import Details"
      ]
    end

    def row_mapping
      common_mapping = [
      :action,
      :fein,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :enrolled_employee_count,
      :new_coverage_policy,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :coverage_start,
      :carrier,
      :plan_selection,
      :ignore,
      :single_plan_hios_id
      ]

      @sponsored_benefit_kind ||= :health
      sponsored_mapping = @sponsored_benefit_kind == :dental ? dental_benefit_mapping : health_benefit_mapping
      combined_mapping = (common_mapping.push sponsored_mapping).flatten!
      combined_mapping
    end

    def dental_benefit_mapping
      [
         :employee_only_rt_contribution,
         :employee_and_spouse_rt_contribution,
         :employer_domestic_partner_rt_contribution,
         :employer_child_under_26_rt_contribution
      ]
    end

    def health_benefit_mapping
      [
          :employee_only_rt_contribution,
          :employee_only_rt_premium,
          :employee_and_spouse_rt_offered,
          :employee_and_spouse_rt_contribution,
          :employee_and_spouse_rt_premium,
          :employee_and_one_or_more_dependents_rt_offered,
          :employee_and_one_or_more_dependents_rt_contribution,
          :employee_and_one_or_more_dependents_rt_premium,
          :family_rt_offered,
          :family_rt_contribution,
          :family_rt_premium
      ]
    end

    include ::Importers::RowSet

    def initialize(file_name, o_stream, default_py_start)
      @spreadsheet = Roo::Spreadsheet.open(file_name)
      @out_stream = o_stream
      @out_csv = CSV.new(o_stream)
      @default_plan_year_start = default_py_start
    end

    def create_model(record_attrs)
      the_action = record_attrs[:action].blank? ? "add" : record_attrs[:action].to_s.strip.downcase
      case the_action
      when "update"
        ::Importers::Mhc::ConversionEmployerPlanYearUpdate.new(record_attrs.merge({:default_plan_year_start => @default_plan_year_start}))
      else
        ::Importers::Mhc::ConversionEmployerPlanYearCreate.new(record_attrs.merge({:default_plan_year_start => @default_plan_year_start}))
      end
    end
  end
end