# frozen_string_literal: true

module Services
  class ApplicableAptcService

    def initialize(enrollment_id, selected_aptc, product_ids, excluding_enrollment_id = nil)
      @enrollment_id = enrollment_id
      @selected_aptc = selected_aptc
      @product_ids = ids_to_strings(product_ids)
      @excluding_enrollment_id = excluding_enrollment_id
    end

    def applicable_aptcs
      factory_instance.fetch_applicable_aptcs
    end

    def aptc_per_member
      factory_instance.fetch_aptc_per_member
    end

    def elected_aptc_per_member
      factory_instance.fetch_elected_aptc_per_member
    end

    private

    def factory_instance
      @factory_instance ||= factory_klass.new(@enrollment_id, @selected_aptc, @product_ids, @excluding_enrollment_id)
    end

    def ids_to_strings(product_ids)
      product_ids.map(&:to_s)
    end

    def factory_klass
      Factories::EligibilityFactory
    end
  end
end
