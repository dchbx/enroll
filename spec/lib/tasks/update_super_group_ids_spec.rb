require 'rails_helper'
Rake.application.rake_require "tasks/update_super_group_ids"
Rake::Task.define_task(:environment)

RSpec.describe 'Migrating carrier specific super group Id', :type => :task do
  let(:plan) { FactoryGirl.build(:plan, hios_id: "88806MA0030001-01", active_year: 2017) }
  let(:default_plan) { FactoryGirl.build(:plan) }
  let(:plan_non_super_group) { FactoryGirl.create(:plan, hios_id: "22222MA0030001-01") }

  before do
    allow(Plan).to receive(:where).and_return([default_plan])
    allow(Plan).to receive(:where).with(hios_id: plan.hios_id, active_year: plan.active_year).and_return([plan])
    Rake::Task["supergroup:update_plan_id"].invoke

  end

  context "for matching plans" do
    it "should update the carrier_specific_field_value" do
      plan.reload
      expect(plan.carrier_special_plan_identifier).to eq "X226"
    end
  end

  context "for non matching plans" do
    it "should not update the carrier_specific_field_value" do
      expect(plan_non_super_group.carrier_special_plan_identifier).to be nil
    end
  end

end
