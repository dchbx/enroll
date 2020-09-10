module FinancialAssistance
  class RelationshipsController < ::ApplicationController
    before_action :find_application

    layout "financial_assistance_nav"

    def index
      @relationships = @application.relationships
    end

    def create
    end

    private
    def find_application
      @application = FinancialAssistance::Application.find_by(id: params[:application_id], family_id: get_current_person.financial_assistance_identifier)
    end
  end
end