# frozen_string_literal: true

module Services
  class AvailableEligibilityService

    def initialize(enrollment_id)
      @enrollment_id = enrollment_id
    end

    def available_eligibility
      factory_klass.new(@enrollment_id).fetch_available_eligibility
    end

    private

    def factory_klass
      Factories::IvlEligibilityFactory
    end
  end
end
