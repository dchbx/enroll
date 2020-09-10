# frozen_string_literal: true

module FinancialAssistance
  class RelationshipsController < ::ApplicationController
    before_action :find_application

    layout "financial_assistance_nav"

    def index
      @relationships = @application.relationships
    end

    #TODO: work in progress
    def create
      @application
      applicant_id = params[:applicant_id]
      relative_id = params[:relative_id]
      predecessor = FinancialAssistance::Applicant.find(applicant_id)
      successor = FinancialAssistance::Applicant.find(relative_id)
      # predecessor = Person.where(id: params[:predecessor_id]).first
      # successor = Person.where(id: params[:successor_id]).first
      @application.add_relationship(successor, params[:kind], true)
      @application.add_relationship(predecessor, FinancialAssistance::Relationship::INVERSE_MAP[params[:kind]])
      @application.reload
      @matrix = @application.build_relationship_matrix
      @missing_relationships = @application.find_missing_relationships(@matrix)
      @relationship_kinds = ::FinancialAssistance::Relationship::RELATIONSHIPS_UI
      @people = nil
      @relationships = @application.find_all_relationships(@matrix)

      respond_to do |format|
        format.html {
          redirect_to application_relationships_path , notice: 'Relationship was successfully updated.'
        }
        format.js
      end
    end

    private

    def find_application
      @application = FinancialAssistance::Application.find_by(id: params[:application_id], family_id: get_current_person.financial_assistance_identifier)
    end
  end
end