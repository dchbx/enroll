require "rails_helper"

module DataTablesAdapter
end

module SponsoredBenefits
  RSpec.describe Organizations::PlanDesignProposalsController, type: :routing do
    routes { SponsoredBenefits::Engine.routes }

    describe "routing" do

      it "routes to #index" do
        expect(:get => "/organizations/plan_design_organizations/1/plan_design_proposals").to route_to("sponsored_benefits/organizations/plan_design_proposals#index", :plan_design_organization_id => "1")
      end

      it "routes to #new" do
        expect(:get => "/organizations/plan_design_organizations/1/plan_design_proposals/new").to route_to("sponsored_benefits/organizations/plan_design_proposals#new", :plan_design_organization_id => "1")
      end

      it "routes to #show" do
        expect(:get => "/organizations/plan_design_organizations/1/plan_design_proposals/1").to route_to("sponsored_benefits/organizations/plan_design_proposals#show", :id => "1", :plan_design_organization_id => "1")
      end

      it "routes to #edit" do
        expect(:get => "/organizations/plan_design_organizations/1/plan_design_proposals/1/edit").to route_to("sponsored_benefits/organizations/plan_design_proposals#edit", :id => "1", :plan_design_organization_id => "1")
      end

      it "routes to #create" do
        expect(:post => "/organizations/plan_design_organizations/1/plan_design_proposals").to route_to("sponsored_benefits/organizations/plan_design_proposals#create", :plan_design_organization_id => "1")
      end

      it "routes to #update via PUT" do
        expect(:put => "/organizations/plan_design_organizations/1/plan_design_proposals/1").to route_to("sponsored_benefits/organizations/plan_design_proposals#update", :id => "1", :plan_design_organization_id => "1")
      end

      it "routes to #update via PATCH" do
        expect(:patch => "/organizations/plan_design_organizations/1/plan_design_proposals/1").to route_to("sponsored_benefits/organizations/plan_design_proposals#update", :id => "1", :plan_design_organization_id => "1")
      end

      it "routes to #destroy" do
        expect(:delete => "/organizations/plan_design_organizations/1/plan_design_proposals/1").to route_to("sponsored_benefits/organizations/plan_design_proposals#destroy", :id => "1", :plan_design_organization_id => "1")
      end

    end
  end
end
