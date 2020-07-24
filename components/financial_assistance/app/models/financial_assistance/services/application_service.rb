module FinancialAssistance
  module Services
    # service the application call from controllers
    class ApplicationService
      attr_reader :family, :code, :application_id

      def initialize(family, opts = {})
        @family = family
        @application_id = opts[:application_id]
        @code = generate_code
      end

      def generate_code
        return :no_app unless family.applications.present?
        return :sync! if drafted_app.present?
        return :copy! if submitted_app.present?
      end

      def drafted_app
        family.application_in_progress
      end

      def submitted_app
        return family.latest_submitted_application if application_id.blank?
        family.applications.find application_id
      end

      def process_application
        send(code)
      end

      def sync!
        new(drafted_app).sync_family_members_with_applicants
      end

      def copy!
        new(submitted_app).copy_application
      end

      def new(application)
        factory_klass.new(application)
      end

      private

      def factory_klass
        FinancialAssistance::Factories::ApplicationFactory
      end
    end
  end
end
