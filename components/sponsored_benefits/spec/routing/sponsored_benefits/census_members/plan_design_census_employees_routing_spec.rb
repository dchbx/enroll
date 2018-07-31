require "rails_helper"

module DataTablesAdapter
end

module SponsoredBenefits
  RSpec.describe CensusMembers::PlanDesignCensusEmployeesController, type: :routing do
    routes { SponsoredBenefits::Engine.routes }

    describe "routing" do

      it "routes to #index" do
        expect(:get => "/plan_design_proposals/1/plan_design_census_employees").to route_to("sponsored_benefits/census_members/plan_design_census_employees#index", :plan_design_proposal_id => "1")
      end

      it "routes to #new" do
        expect(:get => "/plan_design_proposals/1/plan_design_census_employees/new").to route_to("sponsored_benefits/census_members/plan_design_census_employees#new", plan_design_proposal_id: "1")
      end

      it "routes to #show" do
        expect(:get => "/plan_design_proposals/1/plan_design_census_employees/1").to route_to("sponsored_benefits/census_members/plan_design_census_employees#show", :id => "1", plan_design_proposal_id: "1")
      end

      it "routes to #edit" do
        expect(:get => "/plan_design_proposals/1/plan_design_census_employees/1/edit").to route_to("sponsored_benefits/census_members/plan_design_census_employees#edit", :id => "1", plan_design_proposal_id: "1")
      end

      it "routes to #create" do
        expect(:post => "/plan_design_proposals/1/plan_design_census_employees").to route_to("sponsored_benefits/census_members/plan_design_census_employees#create", plan_design_proposal_id: "1")
      end

      it "routes to #update via PUT" do
        expect(:put => "/plan_design_proposals/1/plan_design_census_employees/1").to route_to("sponsored_benefits/census_members/plan_design_census_employees#update", :id => "1", plan_design_proposal_id: "1")
      end

      it "routes to #update via PATCH" do
        expect(:patch => "/plan_design_proposals/1/plan_design_census_employees/1").to route_to("sponsored_benefits/census_members/plan_design_census_employees#update", :id => "1", plan_design_proposal_id: "1")
      end

      it "routes to #destroy" do
        expect(:delete => "/plan_design_proposals/1/plan_design_census_employees/1").to route_to("sponsored_benefits/census_members/plan_design_census_employees#destroy", :id => "1", plan_design_proposal_id: "1")
      end

    end
  end
end
