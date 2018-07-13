module BenefitSponsors
  module Importers::Mhc
    class ConversionEmployeeSet < ::Importers::Mhc::ConversionEmployeeSet

      def create_model(record_attrs)
        the_action = record_attrs[:action].blank? ? "add" : record_attrs[:action].to_s.strip.downcase
        case the_action
          # when "update"
          #   ::Importers::ConversionEmployeeAction.new(record_attrs.merge({:default_hire_date => @default_hire_date}))
        when "delete"
          ::Importers::ConversionEmployeeDelete.new(record_attrs.merge({:default_hire_date => @default_hire_date}))
        else
          BenefitSponsors::Importers::ConversionEmployeeAction.new(record_attrs.merge({:default_hire_date => @default_hire_date}))
        end
      end
    end
  end
end