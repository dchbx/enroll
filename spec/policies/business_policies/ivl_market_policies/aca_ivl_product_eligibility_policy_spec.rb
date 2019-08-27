# frozen_string_literal: true

require 'rails_helper'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  describe BusinessPolicies::IvlMarketPolicies::AcaIvlProductEligibilityPolicy, dbclean: :after_each do
    subject { described_class.new }

    let!(:shop_health_product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, metal_level_kind: :platinum)}

    let!(:ivl_health_product) do
      FactoryBot.create(:benefit_markets_products_health_products_health_product,
                        :silver,
                        csr_variant_id: '01')
    end

    let!(:ivl_health_product) do
      FactoryBot.create(:benefit_markets_products_health_products_health_product,
                        :silver,
                        csr_variant_id: '01')
    end

    let!(:ivl_health_cat_product) do
      FactoryBot.create(:benefit_markets_products_health_products_health_product,
                        :catastrophic,
                        csr_variant_id: '01')
    end

    let!(:ivl_dental_product) {FactoryBot.create(:benefit_markets_products_dental_products_dental_product, :ivl_product)}

    context 'apply_aptc' do
      context 'for success case' do
        before :each do
          @business_policy = subject.execute(ivl_health_product, :apply_aptc)
        end

        it 'should return true when validated' do
          expect(@business_policy[:satisfied]).to eq true
        end

        it 'should not return any fail results' do
          expect(@business_policy[:errors]).to be_empty
        end
      end

      context 'for failure cases' do
        context 'for market_kind' do
          before do
            @business_policy = subject.execute(shop_health_product, :apply_aptc)
          end

          it 'should return false' do
            expect(@business_policy[:satisfied]).to eq false
          end

          it 'should return fail results based on market kind' do
            fail_messages = ["Market Kind of given product is #{shop_health_product.benefit_market_kind} and not aca_individual"]
            expect(@business_policy[:errors]).to eq fail_messages
          end
        end

        context 'for product_kind' do
          before do
            @business_policy = subject.execute(ivl_dental_product, :apply_aptc)
          end

          it 'should return false' do
            expect(@business_policy[:satisfied]).to eq false
          end

          it 'should return fail results based on market kind' do
            fail_messages = ["The given product is of kind #{ivl_dental_product.class} and not #{ivl_health_product.class}",
                             "Metal Level of the given product is #{ivl_dental_product.metal_level_kind} and not one of the [:bronze, :silver, :gold, :platinum]"]
            expect(@business_policy[:errors]).to eq fail_messages
          end
        end

        context 'for metal_level' do
          before do
            @business_policy = subject.execute(ivl_health_cat_product, :apply_aptc)
          end

          it 'should return false' do
            expect(@business_policy[:satisfied]).to eq false
          end

          it 'should return fail results based on market kind' do
            fail_messages = ["Metal Level of the given product is #{ivl_health_cat_product.metal_level_kind} and not one of the [:bronze, :silver, :gold, :platinum]"]
            expect(@business_policy[:errors]).to eq fail_messages
          end
        end
      end

      context 'for invalid inputs' do

        context 'for invalid object' do
          before do
            @object = 'invalid object'
            @business_policy = subject.execute(@object, :apply_aptc)
          end

          it 'should return false' do
            expect(@business_policy[:satisfied]).to eq false
          end

          it 'should return fail results based on market kind' do
            fail_messages = ["Class of the given object is #{@object.class} and not ::BenefitMarkets::Products::Product"]
            expect(@business_policy[:errors]).to eq fail_messages
          end
        end

        context 'for invalid event' do
          before do
            @event = 'invalid event'
            @business_policy = subject.execute(ivl_health_product, @event)
          end

          it 'should return false' do
            expect(@business_policy[:satisfied]).to eq false
          end

          it 'should return fail results based on market kind' do
            fail_messages = ["Invalid event: #{@event}"]
            expect(@business_policy[:errors]).to eq fail_messages
          end
        end
      end
    end
  end
end
