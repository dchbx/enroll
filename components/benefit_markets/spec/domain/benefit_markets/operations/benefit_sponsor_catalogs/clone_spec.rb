# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitMarkets::Operations::BenefitSponsorCatalogs::Clone, dbclean: :after_each do
  before do
    DatabaseCleaner.clean
  end

  let!(:benefit_sponsor_catalog) { FactoryBot.create(:benefit_markets_benefit_sponsor_catalog) }

  context 'success' do
    before do
      @new_bsc = subject.call(benefit_sponsor_catalog: benefit_sponsor_catalog).success
    end

    it 'should return new benefit_sponsor_catalog' do
      expect(@new_bsc).to be_a(::BenefitMarkets::BenefitSponsorCatalog)
    end

    it 'should return a non-persisted benefit_sponsor_catalog' do
      expect(@new_bsc.persisted?).to be_falsy
    end

    it 'should return a benefit_sponsor_catalog with same effective_period' do
      expect(@new_bsc.effective_period).to eq(benefit_sponsor_catalog.effective_period)
    end
  end

  context 'failure' do
    context 'no params' do
      before do
        @result = subject.call({})
      end

      it 'should return a failure with a message' do
        expect(@result.failure).to eq('Missing Key.')
      end
    end

    context 'invalid params' do
      before do
        @result = subject.call({benefit_sponsor_catalog: 'benefit_sponsor_catalog'})
      end

      it 'should return a failure with a message' do
        expect(@result.failure).to eq('Not a valid BenefitSponsorCatalog object.')
      end
    end
  end
end
