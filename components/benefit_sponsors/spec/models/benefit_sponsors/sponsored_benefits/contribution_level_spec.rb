require 'rails_helper'

module BenefitSponsors
  RSpec.describe ::BenefitSponsors::SponsoredBenefits::ContributionLevel do
    describe "given nothing" do
      it "requires a display name" do
        subject.valid?
        expect(subject.errors.has_key?(:display_name)).to be_truthy
      end

      it "requires a contribution unit id" do
        subject.valid?
        expect(subject.errors.has_key?(:contribution_unit_id)).to be_truthy
      end
    end
  end
end
