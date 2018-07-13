require "rails_helper"

class TestAcaModelConcernClass
  include Config::AcaModelConcern
end

describe Config::AcaModelConcern do

  subject { TestAcaModelConcernClass.new }
 
  context ".aca_shop_market_transmit_scheduled_employers" do
    it "should return setting" do
      expect(subject.aca_shop_market_transmit_scheduled_employers).to be_truthy
    end
  end

  context ".aca_shop_market_employer_transmission_day_of_month" do 
    it "should return setting" do
      expect(subject.aca_shop_market_employer_transmission_day_of_month).to be_kind_of(Numeric)
    end
  end
end
