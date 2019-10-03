require 'rails_helper'

describe "import_provider_and_rx_formulary_url" do
  before :all do
    Rake.application.rake_require"tasks/migrations/plans/import_provider_and_rx_formulary_url"
    Rake::Task.define_task(:environment)

    @files = Dir.glob(File.join(Rails.root, "spec/test_data/plan_data/master_xml/2018","*.xlsx"))
    year = @files.first.split("/")[-2].to_i

    read_excel(@files.first)

    @plan = FactoryBot.create(:plan, hios_id: "59763MA0030014-01", active_year: year,
                               rx_formulary_url: nil,
                               provider_directory_url:nil,
                               is_standard_plan: nil,
                               network_information: nil,
                               is_sole_source: nil,
                               is_horizontal: nil,
                               is_vertical: nil)

    @plan2 = FactoryBot.create(:plan, hios_id: "42690MA1300103-01", active_year: year,
                                rx_formulary_url: nil,
                                provider_directory_url:nil,
                                is_standard_plan: nil,
                                network_information: nil,
                                is_sole_source: nil,
                                is_horizontal: nil,
                                is_vertical: nil)

    @health_product = FactoryBot.create(:benefit_markets_products_health_products_health_product, hios_id: "59763MA0030014-01",
                                         application_period: Date.new(year, 1, 1)..Date.new(year, 12, 31),
                                         rx_formulary_url: nil,
                                         provider_directory_url:nil,
                                         is_standard_plan: nil,
                                         network_information: nil,
                                         product_package_kinds: nil)

    @health_product2 = FactoryBot.create(:benefit_markets_products_health_products_health_product, hios_id: "42690MA1300103-01",
                                          application_period: Date.new(year, 1, 1)..Date.new(year, 12, 31),
                                          rx_formulary_url: nil,
                                          provider_directory_url:nil,
                                          is_standard_plan: nil,
                                          network_information: nil,
                                          product_package_kinds: nil)



  end

  context "common_data_from_master_xml" do
    it "should be nil for plan" do
      expect(@plan.rx_formulary_url).to eq nil
      expect(@plan.provider_directory_url).to eq nil
      expect(@plan.network_information).to eq nil
    end

    it "should be nil for product"do
      expect(@health_product2.rx_formulary_url).to eq nil
      expect(@health_product2.provider_directory_url).to eq nil
    end

    context "when import master excel" do
      let(:product_name) { "TEST Blue $1,000 Deductible" }
      let(:plan_name) { "TEST Blue Premium" }
      before(:all) do
        invoke_url_tasks
      end

      it "should update plan attributes" do
        @plan.reload
        expect(@plan.rx_formulary_url).to eq "http://#{@row_info[13]}"
        expect(@plan.provider_directory_url).to eq @row_info[14]
        expect(@plan.network_information).to eq @row_info[11]
        expect(@plan.name).to eq plan_name
      end

      it "should update product attributes" do
        @health_product2.reload
        expect(@health_product2.rx_formulary_url).to eq "http://#{@row_info[13]}"
        expect(@health_product2.provider_directory_url).to eq @row_info[14]
        expect(@health_product2.title).to eq product_name
      end
    end
  end
end

def invoke_url_tasks
 Rake::Task["import:common_data_from_master_xml"].invoke(@files.first)
end

def read_excel(file)
  result = Roo::Spreadsheet.open(file)
  sheet_data = result.sheet("2018_QHP")
  @row_info = sheet_data.row(2)
end
