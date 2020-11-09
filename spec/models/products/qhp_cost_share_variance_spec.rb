# frozen_string_literal: true

require 'rails_helper'

describe Products::QhpCostShareVariance, :type => :model do
  let!(:shop_product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_shop) }
  let!(:fehb_product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, hios_base_id: shop_product.hios_id, benefit_market_kind: :fehb) }
  let(:hios_id)      { shop_product.hios_id }
  let(:active_year)  { shop_product.active_year }
  let(:qcsv) { FactoryBot.build(:products_qhp_cost_share_variance, hios_plan_and_variant_id: hios_id) }
  let(:product_qhp) { FactoryBot.create(:products_qhp, qhp_cost_share_variances: [qcsv], active_year: active_year) }

  it "should return shop product" do
    expect(product_qhp.qhp_cost_share_variances.first.product_for('aca_shop')).to eq shop_product
  end

  it "should return fehb product" do
    expect(product_qhp.qhp_cost_share_variances.first.product_for('fehb')).to eq fehb_product
  end
end
