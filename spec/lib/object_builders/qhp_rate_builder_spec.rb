require 'rails_helper'
require Rails.root.join('lib', 'object_builders', 'qhp_rate_builder')

describe QhpRateBuilder do

  let(:plan){ FactoryGirl.create(:plan) }

  it "should return qhp builder object" do
    @rates_hash = {
      items: [{
        :effective_date => "2016-01-01",
        :expiration_date => "2016-12-31",
        :plan_id => plan.hios_id,
        :age_number => 20,
        :primary_enrollee => 256.41
      }]
    }
    qhp = QhpRateBuilder.new()
    qhp.add(@rates_hash, "new")
    qhp.run
    plan.reload
    expect(plan.premium_tables.size).to eq 1
    expect(plan.premium_tables.first.age).to eq @rates_hash[:items].first[:age_number]
    expect(plan.premium_tables.first.cost).to eq @rates_hash[:items].first[:primary_enrollee]
    expect(plan.premium_tables.first.start_on.to_date).to eq @rates_hash[:items].first[:effective_date].to_date
    expect(plan.premium_tables.first.end_on.to_date).to eq @rates_hash[:items].first[:expiration_date].to_date
  end

end