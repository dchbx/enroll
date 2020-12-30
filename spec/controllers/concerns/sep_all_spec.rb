require 'rails_helper'

class FakesController < ApplicationController
  include SepAll
end

describe FakesController do
  let(:qle){FactoryBot.build(:qualifying_life_event_kind)}
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

    it "marketkind should return shop" do
      expect(qle.market_kind).to eq "shop"
    end
  end

  context 'For covid qle' do
    let(:qle) { FactoryBot.build(:qualifying_life_event_kind, reason: 'covid-19', effective_on_kinds: ['first_of_this_month', 'fixed_first_of_next_month'], market_kind: :shop) }
    let(:qle_on) { TimeKeeper.date_of_record }
    let(:effective_date_options) {
      [[qle_on.beginning_of_month.to_s, "first_of_this_month"], [qle_on.end_of_month.next_day.to_s, "fixed_first_of_next_month"]]
    }

    before do
      controller.instance_variable_set("@qle", qle)
    end

    it 'should return qle date option kinds' do
      expect(subject.calculate_rule).to eq effective_date_options
    end
  end

  context 'For fixed_first_of_next_month rule' do
    let(:qle) { FactoryBot.build(:qualifying_life_event_kind, effective_on_kinds: ['fixed_first_of_next_month']) }

    before do
      controller.instance_variable_set("@qle", qle)
    end

    it 'should return alias name of fixed_first_of_next_month' do
      expect(subject.calculate_rule).to eq ['First of month after event']
    end
  end

  context 'set qle_ivl for resident role' do
    let!(:qle) {FactoryBot.create(:qualifying_life_event_kind, market_kind: "individual")}
    let(:resident_person) {FactoryBot.create(:person, :with_resident_role)}
    let(:resident_family) { FactoryBot.create(:family, :with_primary_family_member, person: resident_person) }

    before do
      subject.getMarket(resident_family)
    end

    it 'should return qle_ivl instance variable for resident role' do
      expect(subject.instance_variable_get(:@qle_ivl)).to eq [qle]
    end
  end
end
