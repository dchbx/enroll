require 'rails_helper'

# AcaShopRenewalApplicationConfiguration test cases
module BenefitMarkets
  module Configurations
    RSpec.describe AcaShopRenewalApplicationConfiguration, type: :model, dbclean: :after_each do
      context "ability to create, validate and persist instances of this class" do
        subject { build :benefit_markets_aca_shop_renewal_application_configuration }

        it "should be valid" do
          expect(subject).to be_valid
        end
      end
    end
  end
end
