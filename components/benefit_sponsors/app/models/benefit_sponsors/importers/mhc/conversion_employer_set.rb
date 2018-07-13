module BenefitSponsors
  module Importers::Mhc
    class ConversionEmployerSet < ::Importers::Mhc::ConversionEmployerSet

      def create_model(record_attrs)
        row_action = record_attrs[:action].blank? ? "add" : record_attrs[:action].to_s.strip.downcase

        if row_action == 'add'
           BenefitSponsors::Importers::Mhc::ConversionEmployerCreate.new(record_attrs.merge({:registered_on => @conversion_date}))
        elsif row_action == 'update'
          ::Importers::Mhc::ConversionEmployerUpdate.new(record_attrs.merge({:registered_on => @conversion_date}))
        else
          puts "Please provide the excel header on action column either add or update"
        end
      end
    end
  end
end

