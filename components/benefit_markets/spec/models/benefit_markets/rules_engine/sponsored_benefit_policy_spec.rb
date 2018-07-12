require "rails_helper"

module BenefitMarkets
  RSpec.describe RulesEngine::SponsoredBenefitPolicy do
    let(:policy) { ::BenefitMarkets::RulesEngine::SponsoredBenefitPolicy }


    subject { policy.call(product_package) }

    describe "given a package with no kind" do
      let(:product_package) do
        double(
          is_metal_level_package?: false,
          is_sole_source_package?: false,
          is_carrier_package?: false
        )
      end

      it "is false" do
        expect(subject.failed?).to be_truthy
      end
    end

    describe "given:
                - a metal level package
                - with a reference product selected
                - but no metal level selected" do
       
      let(:product_package_errors) {
        double
      }

      let(:product_package) do
        double(
          is_metal_level_package?: true,
          is_sole_source_package?: false,
          is_carrier_package?: false,
          metal_level: nil,
          reference_product: double,
          errors: product_package_errors
        )
      end

      before :each do
        allow(product_package_errors).to receive(:add).with(:metal_level, "must have a metal level selected")
      end

      it "is false" do
        expect(subject.failed?).to be_truthy
      end
    end
  end
end
