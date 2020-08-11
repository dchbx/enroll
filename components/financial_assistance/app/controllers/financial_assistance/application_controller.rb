module FinancialAssistance
  class ApplicationController < ::ApplicationController
    protect_from_forgery with: :exception

    layout "layouts/financial_assistance"
  end
end
