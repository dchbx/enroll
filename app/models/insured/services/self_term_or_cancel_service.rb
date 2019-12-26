# frozen_string_literal: true

module Insured
  module Services
    class SelfTermOrCancelService
      include ActionView::Helpers::NumberHelper

      def initialize(attrs)
        @enrollment_id  = attrs[:enrollment_id]
        @family_id      = attrs[:family_id]
        @term_date      = attrs[:term_date].present? ? Date.strptime(attrs[:term_date], '%m/%d/%Y') : TimeKeeper.date_of_record
        @term_or_cancel = attrs[:term_or_cancel]
        @elected_aptc_pct = attrs[:elected_aptc_pct]
        @factory_class  = ::Insured::Factories::SelfServiceFactory
      end

      def find
        form_params = @factory_class.find(@enrollment_id, @family_id)
        attributes_to_form_params(form_params)
      end

      def term_or_cancel
        @factory_class.term_or_cancel(@enrollment_id, @term_date, @term_or_cancel)
      end

      def update_aptc
        @factory_class.update_aptc(@enrollment_id, @elected_aptc_pct.to_f, @elected_aptc_pct.to_f.to_money)
      end

      def attributes_to_form_params(attrs)
        {
          :enrollment => ::Insured::Serializers::EnrollmentSerializer.new(attrs[:enrollment]).to_hash,
          :market_kind => attrs[:qle].present? ? attrs[:qle].market_kind : nil,
          :product => ::Insured::Services::ProductService.new(attrs[:enrollment].product).find,
          :family => ::Insured::Serializers::FamilySerializer.new(attrs[:family]).to_hash,
          :is_aptc_eligible => attrs[:is_aptc_eligible]
        }
      end
    end
  end
end
