require 'rails_helper'

module BenefitMarkets
  class MockContributionLevel
    attr_accessor :contribution_unit_id
    attr_accessor :contribution_factor
    attr_accessor :min_contribution_factor
    attr_accessor :contribution_cap
    attr_accessor :display_name
    attr_accessor :order
    attr_accessor :is_offered

    def initialize(opts = {})
      opts.each_key do |k|
        self.send("#{k}=",opts[k])
      end
    end
  end

  RSpec.describe ContributionModels::ContributionModelBuilder do
    describe "given a contribution model for Fehb" do
      let(:contribution_unit) do
        ContributionModels::PercentWithCapContributionUnit.new(
          name: "employee_only",
          display_name: "Employee Only",
          member_relationship_maps: [member_relationship_map],
          default_contribution_factor: 0.75,
          default_contribution_cap: 500.00,
          order: 0
        )
      end

      let(:member_relationship_map) do
        ContributionModels::MemberRelationshipMap.new(
          relationship_name: "employee",
          operator: :==,
          count: 1
        )
      end

      let(:member_relationship) do
        ContributionModels::MemberRelationship.new(
          relationship_name: "employee",
          relationship_kinds: ["self"]
        )
      end
      let(:contribution_units) { [contribution_unit] }
      let(:member_relationships) { [member_relationship] }

      let(:contribution_model) do
        ContributionModels::ContributionModel.new(
          :sponsor_contribution_kind => "Whatever",
          :contribution_units => contribution_units,
          :member_relationships => member_relationships,
          :title => "Federal Heath Benefits"
        )
      end

      let(:builder) { ContributionModels::ContributionModelBuilder.new }

      describe "#build_contribution_unit_values" do
        let(:sponsored_benefit) { double("sponsored benefit mock", :contribution_levels => cl_builder) }
        let(:cl_builder) { double }

        let(:subject) { builder.build_contribution_levels(contribution_model, sponsored_benefit) }

        before :each do
          allow(cl_builder).to receive(:build).with(no_args).and_return(::BenefitMarkets::MockContributionLevel.new)
        end

        it "builds the correct number" do
          expect(subject.length).to eq 1
        end

        it "builds the correct display_name" do
          expect(subject.first.display_name).to eq "Employee Only"
        end

        it "builds the correct order" do
          expect(subject.first.order).to eq 0
        end

        it "build the specified kind of contribution level" do
          expect(subject.first.kind_of?(::BenefitMarkets::MockContributionLevel)).to be_truthy
        end

        it "properly assigns the contribution unit" do
          expect(subject.first.contribution_unit_id).to eq contribution_unit.id
        end
      end
    end
  end
end
