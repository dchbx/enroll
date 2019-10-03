require 'rails_helper'

describe "plan_cross_walk" do
  before :all do
    @plan_2017 = FactoryBot.create(:plan, active_year: 2017, hios_id: "42690MA1234502-01", hios_base_id: "42690MA1234502", csr_variant_id: "01")
    @plan_2018 = FactoryBot.create(:plan, active_year: 2018, hios_id: "42690MA1234502-01", hios_base_id: "42690MA1234502", csr_variant_id: "01")

    @product_2017 = FactoryBot.create(:benefit_markets_products_health_products_health_product, hios_id: "42690MA1234502-01", hios_base_id: "42690MA1234502", csr_variant_id: "01", application_period: Date.new(2017, 1, 1)..Date.new(2017, 12, 31))
    @product_2018 = FactoryBot.create(:benefit_markets_products_health_products_health_product, hios_id: "42690MA1234502-01", hios_base_id: "42690MA1234502", csr_variant_id: "01", application_period: Date.new(2018, 1, 1)..Date.new(2018, 12, 31))

    Rake.application.rake_require "tasks/migrations/plans/plan_cross_walk"
    Rake::Task.define_task(:environment)
  end

  context "passing scenarios" do
    it "should run the rake" do
      expect(@plan_2017.renewal_plan_id).to eq nil
      expect(@product_2017.renewal_product_id).to eq nil
      invoke_cross_walk_tasks
    end

    it "should update the renewal_plan_id " do
      @plan_2017.reload
      expect(@plan_2017.renewal_plan_id).not_to eq nil
    end

    it "should update the renewal_product_id " do
      @product_2017.reload
      expect(@product_2017.renewal_product_id).not_to eq nil
    end
  end

  context "when plan renewing to the same hios id during renewal year scenario" do
    before :all do
      @plan_2017.update_attributes(renewal_plan_id: nil, hios_id: "42690MA1234503-01")
      @product_2017.update_attributes(renewal_product_id: nil, hios_id: "42690MA1234503-01")
      @plan_2018.update_attributes(renewal_plan_id: nil)
      @product_2018.update_attributes(renewal_product_id: nil)
    end
    it "should run the rake" do
      expect(@plan_2017.renewal_plan_id).to eq nil
      expect(@product_2017.renewal_product_id).to eq nil
      invoke_cross_walk_tasks
    end

    it "should update the renewal_plan_id to same hios id in renewal year if there is no old plan data in the template" do
      @plan_2017.reload
      expect(@plan_2017.renewal_plan_id).to eq @plan_2018.id
    end

    it "should update the renewal_product_id to same hios id in renewal year if there is no old product data in the template" do
      @product_2017.reload
      expect(@product_2017.renewal_product_id).to eq @product_2018.id
    end
  end

  after :all do
    DatabaseCleaner.clean
  end
end

def invoke_cross_walk_tasks
  files = Dir.glob(File.join(Rails.root, "spec/test_data/plan_data", "cross_walk", "2018", "**", "*.xml"))
  Rake::Task["xml:plan_cross_walk"].reenable
  Rake::Task["xml:plan_cross_walk"].invoke(files.first)
end
