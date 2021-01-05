# frozen_string_literal: true

module Services
  class AvailableEligibilityService

    def initialize(enrollment_id, effective_on, excluding_enrollment_id = nil)
      @enrollment_id = enrollment_id
      @excluding_enrollment_id = excluding_enrollment_id
      @effective_on = effective_on
    end

    def available_eligibility
      factory_klass.new(@enrollment_id, @effective_on, nil, [], @excluding_enrollment_id).fetch_available_eligibility
    end

    private

    def factory_klass
      Factories::EligibilityFactory
    end
  end
end
