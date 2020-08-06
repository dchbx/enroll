# frozen_string_literal: true

require 'rails_helper'

module BenefitMarkets
  RSpec.describe Forms::ProductForm, dbclean: :after_each do
    describe '::for_new' do
      let(:product) { create :benefit_markets_products_product }
      let(:future_product) { create :benefit_markets_products_product }
      let(:date) { TimeKeeper.date_of_record }
      let(:future_date) { (date + 1.year) }
      let!(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product) }

      context "#with current date" do

        subject { BenefitMarkets::Forms::ProductForm.for_new(date) }

        it 'should instantiate a new Product Form' do
          expect(subject).to be_an_instance_of(BenefitMarkets::Forms::ProductForm)
        end

        it 'should return false if rates are present' do
          expect(subject.fetch_results.is_late_rate).to eq false
        end
      end

      context "#with future date" do
        subject { BenefitMarkets::Forms::ProductForm.for_new(future_date) }

        it 'should return true if rates are not present' do
          future_product.application_period = Date.new(future_date.year, 1, 1)..Date.new(future_date.year, 12, 31)
          future_product.premium_tables = nil
          future_product.save
          expect(subject.fetch_results.is_late_rate).to eq true
        end
      end
    end
  end
end
