require 'rails_helper'

module BenefitMarkets
  RSpec.describe Products::ProductPackageForm, type: :model do
    describe '::for_new' do
      let(:catalog) { create :benefit_markets_benefit_market_catalog }
      subject { BenefitMarkets::Products::ProductPackageForm.for_new }

      it 'instantiates a new Product Package Form' do
        expect(subject).to be_an_instance_of(BenefitMarkets::Products::ProductPackageForm)
      end
    end
  end
end
