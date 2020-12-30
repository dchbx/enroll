# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Operations::BenefitSponsorCatalogs::FetchMinimumParticipation, dbclean: :after_each do

  let(:contribution_factors){
    {
      :zero_percent_sponsor_fixed_percent_contribution_model => 0,
      :fifty_percent_sponsor_fixed_percent_contribution_model => 0.667
    }
  }

  let(:effective_period) {
    TimeKeeper.date_of_record.beginning_of_year..TimeKeeper.date_of_record.end_of_year
  }

  let(:params) {
    {
      product_package: product_package,
      calender_year: effective_period.min.year
    }
  }

  let(:product_package) {
    double(assigned_contribution_model: contribution_model, benefit_kind: :aca_shop, contribution_model: contribution_model)
  }

  let(:contribution_model) {
    double(key: :fifty_percent_sponsor_fixed_percent_contribution_model)
  }

  context 'aca shop market' do
    context 'for product package with fifty percent contribution model' do
      let(:contribution_model) {
        double(key: :fifty_percent_sponsor_fixed_percent_contribution_model)
      }

      it 'should return two thirds minimum contribution' do
        result = subject.call(params)
        expect(result.success?).to be_truthy
        expect(result.success).to eq (2/3.0)
      end
    end

    context 'for product package with fifty percent contribution model' do
      let(:contribution_model) {
        double(key: :zero_percent_sponsor_fixed_percent_contribution_model)
      }
      
      it 'should return zero minimum contribution' do
        result = subject.call(params)
        expect(result.success?).to be_truthy
        expect(result.success).to eq 0
      end
    end

    context 'when contribution model key missing' do
      let(:contribution_model) {
        double(key: nil)
      }

      it 'should return failure' do
        result = subject.call(params)

        expect(result.failure?).to be_truthy
        expect(result.failure).to eq "contribution key missing."
      end
    end

    context 'when contribution model key different from settings' do
      let(:contribution_model) {
        double(key: :list_bill_contribution_model)
      }

      it 'should return failure' do
        result = subject.call(params)

        expect(result.failure?).to be_truthy
        expect(result.failure).to eq "unable to find minimum contribution for given contribution model."
      end
    end
  end
end
