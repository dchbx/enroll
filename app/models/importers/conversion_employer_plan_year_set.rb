module Importers
  class ConversionEmployerPlanYearSet
    def headers
      [
"Action",
"FEIN",
"Doing Business As",
"Legal Name",
"Physical Address 1",
"Physical Address 2",
"City",
"State",
"Zip",
"County",
"Mailing Address 1",
"Mailing Address 2",
"City",
"State",
"Zip",
"Contact First Name",
"Contact Last Name",
"Contact Email",
"Contact Phone",
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
"Plan HIOS Id",
"Most Enrollees - Plan Name",
"Most Enrollees - Plan HIOS Id",
"Reference Plan - Name",
"Reference Plan - HIOS Id",
"Employer Contribution -  Employee",
"Employer Contribution - Spouse",
"Employer Contribution - Domestic Partner",
"Employer Contribution - Child under 26",
"Employer Contribution - Child over 26",
"Employer Contribution - Disabled child over 26",
"Import Status",
"Import Details"
    ]
    end

    def row_mapping
      [
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
      :single_plan_hios_id,
      :ignore,
      :most_common_hios_id,
      :ignore,
      :reference_plan_hios_id
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
        ::Importers::ConversionEmployerPlanYearUpdate.new(record_attrs.merge({:default_plan_year_start => @default_plan_year_start}))
      else
        ::Importers::ConversionEmployerPlanYearCreate.new(record_attrs.merge({:default_plan_year_start => @default_plan_year_start}))
      end
    end
  end
end
