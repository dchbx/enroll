require 'rails_helper'

# AcaShopApplicationConfiguration test cases
module BenefitMarkets
  module Configurations
    RSpec.describe AcaShopConfiguration, type: :model, dbclean: :after_each do
      context "ability to create, validate and persist instances of this class" do
        subject { build :benefit_markets_aca_shop_configuration }

        it "should be valid" do
          expect(subject).to be_valid
        end
      end
    end
  end
end
