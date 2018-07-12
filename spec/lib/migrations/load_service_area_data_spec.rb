require 'rails_helper'

RSpec.shared_examples "a carrier service area" do |attributes|
  attributes.each do |attribute, value|
    it "should return #{value} from ##{attribute}" do
      expect(subject.send(attribute)).to eq(value)
    end
  end
end

RSpec.describe 'Carrier Service Area Imports', :type => :task do

  context "service_area:update_service_area" do

    before :all do
      DatabaseCleaner.clean
      Rake.application.rake_require 'tasks/migrations/load_service_area_data'
      Rake::Task.define_task(:environment)
      create(:rating_area, county_name: 'Suffolk', zip_code: '10010')
      invoke_task
    end
    after :all do
      DatabaseCleaner.clean
    end

    let!(:imported_areas) { CarrierServiceArea.all }    

    context "it creates ServiceArea elements correctly" do
      subject { imported_areas.where(:serves_entire_state => true).first }

      it_should_behave_like "a carrier service area", {
                                                  active_year: '2017',
                                                  issuer_hios_id: '82569',
                                                  service_area_id: 'MAS001',
                                                  service_area_name: 'BMC HealthNet Plan Select Network',
                                                  serves_entire_state: true,
                                                  county_name: nil,
                                                  county_code: nil,
                                                  state_code: nil,
                                                  service_area_zipcode: nil,
                                                  partial_county_justification: nil
                                                }
    end

    context "for elements that serve partial state but total county" do
      subject { imported_areas.where(:county_name => 'Suffolk', :county_code => '025', :state_code => '25', :service_area_zipcode => '10010', :service_area_id => "MAS001").first }
      it_should_behave_like "a carrier service area", {
                                                  active_year: '2017',
                                                  issuer_hios_id: '82569',
                                                  service_area_id: 'MAS001',
                                                  service_area_name: 'BMC HealthNet Plan Select Network',
                                                  serves_entire_state: false,
                                                  county_name: 'Suffolk',
                                                  county_code: '025',
                                                  state_code: '25',
                                                  service_area_zipcode: '10010',
                                                  partial_county_justification: nil
                                                }
    end

    context "for elements that serve partial state and partial county" do
      subject { imported_areas.where(:county_name => 'Middlesex', :county_code => "017", :state_code => '25', :service_area_zipcode => "01730").first}

      it_should_behave_like "a carrier service area", {
                                                  active_year: '2017',
                                                  issuer_hios_id: '82569',
                                                  service_area_id: 'MAS001',
                                                  service_area_name: 'BMC HealthNet Plan Select Network',
                                                  serves_entire_state: false,
                                                  county_name: 'Middlesex',
                                                  county_code: '017',
                                                  state_code: '25',
                                                  service_area_zipcode: '01730',
                                                }
      it "assigns the partial county justification correctly" do
        expect(subject.partial_county_justification).to match(/Network adequacy for these products centers around the 4 hospitals that are in the network./)
      end
    end

    context "it created the correct number of zip code sub areas" do
      subject { CarrierServiceArea.where(county_name: "Middlesex", service_area_name: "BMC HealthNet Plan Select Network") }

      it "created many service areas for each imported zip code" do
        expect(subject.count).to eq 51
      end
    end

    private

    def invoke_task
      Rake.application.invoke_task("load_service_reference:update_service_areas[#{Rails.root}/spec/test_data/plan_data/service_areas/2017/SHOP_SA_BMCHP.xlsx]")
    end
  end
end
