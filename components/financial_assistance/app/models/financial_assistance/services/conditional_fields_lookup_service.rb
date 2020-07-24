module FinancialAssistance
  module Services
    # This service will return boolean if the conditional fields has to be displayed.
    class ConditionalFieldsLookupService

      APPLICANT_DRIVER_QUES = [:is_required_to_file_taxes, :is_claimed_as_tax_dependent].freeze

      def displayable_field?(class_name, bson_id, attribute)
        return false unless class_name.present?
        class_name.downcase!
        return true if driver_que?(class_name, attribute)
        @factory = factory_klass.new(class_name, bson_id, attribute)
        @factory.conditionally_displayable?
      end

      private

      def driver_que?(class_name, field_name)
        case class_name
        when "applicant"
          APPLICANT_DRIVER_QUES.include? field_name.to_sym
        else
          false
        end
      end

      def factory_klass
        FinancialAssistance::Factories::ConditionalFieldsLookupFactory
      end
    end
  end
end
