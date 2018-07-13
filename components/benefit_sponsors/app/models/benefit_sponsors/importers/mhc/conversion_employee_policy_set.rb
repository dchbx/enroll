module BenefitSponsors
  module Importers::Mhc
    class ConversionEmployeePolicySet < ::Importers::Mhc::ConversionEmployeePolicySet

      def initialize(file_name, o_stream, config, dependents)
        @default_policy_start = config["conversions"]["employee_policies_date"]
        @plan_year =  config["conversions"]["employee_policy_year"]
        @mid_year_conversion = config["conversions"]["mid_year_conversion"]
        @spreadsheet = Roo::Spreadsheet.open(file_name)
        @out_stream = o_stream
        @out_csv = CSV.new(o_stream)
        @dependents = dependents
      end

      def create_model(record_attrs)
        the_action = record_attrs[:action].blank? ? "add" : record_attrs[:action].to_s.strip.downcase
        case the_action
        when "delete"
          ::Importers::ConversionEmployeePolicyDelete.new(record_attrs.merge({:default_policy_start => @default_policy_start, :plan_year => @plan_year}))
        else
          BenefitSponsors::Importers::ConversionEmployeePolicyAction.new(record_attrs.merge({:default_policy_start => @default_policy_start, :plan_year => @plan_year}))
        end
      end
    end
  end
end
