require 'rails_helper'

class FakesController < ApplicationController
  include SepAll
end

describe FakesController do
  let(:qle){FactoryGirl.build(:qualifying_life_event_kind)}
  let(:fifteen_day_rule) { ["15th of month"] }
  let(:end_month_rule) { ['End of Month'] }

  context "Should Calculate Rules for Effective Kind" do 
    before do
      controller.instance_variable_set("@qle", qle)
    end

    it "first_of_month" do  
      expect(subject.calculate_rule).to eq fifteen_day_rule
    end
    
    it "first_of_next_month" do
      expect(end_month_rule).to eq end_month_rule
    end

  end
end