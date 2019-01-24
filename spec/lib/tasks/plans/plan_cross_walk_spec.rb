require 'rails_helper'
Rake.application.rake_require "tasks/plans/plan_cross_walk"

describe "plan_cross_walk" do
  before :all do
    @plan_2017 = FactoryGirl.create(:plan, active_year: 2017, hios_id: "42690MA1234502-01", hios_base_id: "42690MA1234502", csr_variant_id: "01")
    @plan_2018 = FactoryGirl.create(:plan, active_year: 2018, hios_id: "42690MA1234502-01", hios_base_id: "42690MA1234502", csr_variant_id: "01")
    @retired_plan_2017 = FactoryGirl.create(:plan, active_year: 2017, hios_id: "42690MA1234504-01", hios_base_id: "42690MA1234504", csr_variant_id: "01")

    # plans that are not present in the crosswalk template should automatically get mapped to renewal plan if one is present.
    @plan_2017_1 = FactoryGirl.create(:plan, active_year: 2017, hios_id: "42690MA1234505-01", hios_base_id: "42690MA1234505", csr_variant_id: "01")
    @plan_2018_1 = FactoryGirl.create(:plan, active_year: 2018, hios_id: "42690MA1234505-01", hios_base_id: "42690MA1234505", csr_variant_id: "01")

    Rake::Task.define_task(:environment)
    invoke_cross_walk_tasks
  end

  context "when renewal plan is present" do
    it "should map to renewal plan" do
      @plan_2017.reload
      expect(@plan_2017.renewal_plan_id).to eq @plan_2018.id
    end
  end

  context "plan retiring" do
    it "should not map to a renewal plan if current plan is retired" do
      expect(@retired_plan_2017.renewal_plan_id).to eq nil
    end
  end

  context "when plans are not present in the template" do
    it "should automatically get mapped to renewal plan if one is present" do
      @plan_2017_1.reload
      expect(@plan_2017_1.renewal_plan_id).to eq @plan_2018_1.id
    end
  end


  after :all do
    DatabaseCleaner.clean
  end
end

def invoke_cross_walk_tasks
  files = Dir.glob(File.join(Rails.root, "spec/test_data/plan_data", "cross_walk", "2018", "**", "*.xml"))
  Rake::Task["xml:plan_cross_walk"].reenable
  Rake::Task["xml:plan_cross_walk"].invoke(files)
end
