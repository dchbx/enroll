# frozen_string_literal: true

module BenefitSponsors
  module Importers::Mhc
    class ConversionEmployerPlanYearSet < ::Importers::Mhc::ConversionEmployerPlanYearSet

      def initialize(file_name, o_stream, config)
        @spreadsheet = Roo::Spreadsheet.open(file_name)
        @out_stream = o_stream
        @out_csv = CSV.new(o_stream)

        @default_plan_year_start = config["conversions"]["plan_year_date"]
        @plan_year_end = config["conversions"]["plan_year_end_date"]
        @mid_year_conversion = config["conversions"]["mid_year_conversion"]
        @orginal_plan_year_begin_date = config["conversions"]["orginal_plan_year_begin_date"]
        @sponsored_benefit_kind = config["conversions"]["sponsored_benefit_kind"]
      end

      def recalc_plan_year_dates_from_sheet(coverage_start_date)
        coverage_start = Date.strptime(coverage_start_date, '%m/%d/%Y')
        corrected_coverage_start = if coverage_start.month <= @default_plan_year_start.month
                                     coverage_start.change(year: @default_plan_year_start.year)
                                   else
                                     if coverage_start > @default_plan_year_start
                                       coverage_start
                                     else
                                       coverage_start.change(year: (@default_plan_year_start.year - 1))
                                                                end
                                   end

        @orginal_plan_year_begin_date = corrected_coverage_start
        @plan_year_end = corrected_coverage_start.next_year.prev_day
      end

      def create_model(record_attrs)
        recalc_plan_year_dates_from_sheet(record_attrs[:coverage_start]) if @mid_year_conversion

        the_action = record_attrs[:action].blank? ? "add" : record_attrs[:action].to_s.strip.downcase

        plan_year_attrs = record_attrs.merge({
                                               default_plan_year_start: @default_plan_year_start,
                                               plan_year_end: @plan_year_end,
                                               mid_year_conversion: @mid_year_conversion,
                                               orginal_plan_year_begin_date: @orginal_plan_year_begin_date,
                                               sponsored_benefit_kind: @sponsored_benefit_kind
                                             })

        case the_action
        when "update"
          ConversionEmployerPlanYearUpdate.new(plan_year_attrs)
        else
          ConversionEmployerPlanYearCreate.new(plan_year_attrs)
        end
      end
    end
  end
end

