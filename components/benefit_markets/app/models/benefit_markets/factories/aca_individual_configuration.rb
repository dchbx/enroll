module BenefitMarkets
  module Factories
    class AcaIndividualConfiguration
      def self.build
        BenefitMarkets::Configurations::AcaIndividualConfiguration.new(
          initial_application_configuration: BenefitMarkets::Configurations::AcaIndividualInitialApplicationConfiguration.new
        )
      end

      def self.call(initial_application_configuration:, mm_enr_due_on:, open_enrl_end_on:, open_enrl_start_on:, vr_due:, vr_os_window:)
        BenefitMarkets::Configurations::AcaIndividualConfiguration.new initial_application_configuration: initial_application_configuration,
          mm_enr_due_on: mm_enr_due_on,
          open_enrl_end_on: open_enrl_end_on,
          open_enrl_start_on: open_enrl_start_on,
          vr_due: vr_due,
          vr_os_window: vr_os_window
      end
    end
  end
end