# frozen_string_literal: true

module FinancialAssistance
  module Services
    # service the application call from controllers
    class ApplicationService
      attr_reader :code, :application_id

      def initialize(application_id:)
        @application_id = application_id
        @application = fetch_application(application_id)
      end

      def fetch_application(application_id)
        ::FinancialAssistance::Application.where(id: application_id.to_s).first
      end

      def applications
        ::FinancialAssistance::Application.where(family_id: @application.family_id)
      end

      def latest_submitted_application
        applications.order_by(:submitted_at => 'desc').first
      end

      def drafted_app
        ::FinancialAssistance::Application.where(family_id: @application.family_id, aasm_state: 'draft').first
      end

      def submitted_app
        return latest_submitted_application if application_id.blank?
        applications.find application_id
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
