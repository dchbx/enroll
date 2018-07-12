require "rails_helper"

module BenefitSponsors
  RSpec.describe BenefitSponsors::SponsoredBenefits::FixedPercentSponsorContribution do
    describe "given a contribution level with no contribution factor" do
      let(:contribution_level) {
        {
          :display_name => "Employee Only",
          :order => 1,
          :contribution_unit_id => 1
        }
      }

      subject do
        SponsoredBenefits::FixedPercentSponsorContribution.new(
          contribution_levels: [contribution_level]
        )
      end

      it "has invalid contribution levels" do
        subject.valid?
        expect(subject.errors.keys.include?(:contribution_levels)).to be_truthy
      end
    end

    # FIXME: This constraint should possibly be enforced in the domain logic
    #        layer - and is currently causing loading issues for MPY
    #        employers. As such I'm disabling it until we can either put
    #        it back or move it to the domain layer.
=begin
    describe "given a contribution level with no contribution < minimum" do
      let(:contribution_level) {
        {
          :display_name => "Employee Only",
          :order => 1,
          :contribution_unit_id => 1,
          :min_contribution_factor => 0.3,
          :contribution_factor => 0.29
        }
      }

      subject do
        SponsoredBenefits::FixedPercentSponsorContribution.new(
          contribution_levels: [contribution_level]
        )
      end

      it "has invalid contribution levels" do
        subject.valid?
        expect(subject.errors.keys.include?(:contribution_levels)).to be_truthy
      end
    end
=end
  end
end
