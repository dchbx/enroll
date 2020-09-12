# frozen_string_literal: true

module FinancialAssistance
  class ApplicationController < ::ApplicationController
    protect_from_forgery with: :exception

    before_action :verify_financial_assistance_enabled

    helper ::FinancialAssistance::Engine.helpers

    layout "layouts/financial_assistance"

    private

    def verify_financial_assistance_enabled
      return render(file: 'public/404.html', status: 404) unless ::EnrollRegistry.feature_enabled?(:financial_assistance)
      true
    end
  end
end
