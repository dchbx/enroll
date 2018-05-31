require "rails_helper"

RSpec.describe "broker_agencies/profiles/_employers.html.erb" do
  let(:organization) { FactoryGirl.create(:organization) }
  let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, organization: organization) }
  let(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization) }
  before :each do
    assign :broker_agency_profile, broker_agency_profile
    assign :employer_profiles, [employer_profile]
    assign :page_alphabets, ['a']
    assign :general_agency_profiles, []
    allow(view).to receive(:controller_name).and_return 'profiles'
  end

  describe 'with modify permissions for DC' do
    before :each do
      render template: "broker_agencies/profiles/_employers.html.erb"
    end
    context "General Agency can be enabled or disabled via settings" do
      # passes in DC and MA based on Settings
      context "when enabled", :if => Settings.aca.general_agency_enabled do
        it "should have general agency" do
          expect(rendered).to match(/General Agencies/)
        end

        it "should have button for ga assign" do
          expect(rendered).to have_selector('#assign_general_agency')
        end

        it "should not have a blocked button for ga assign" do
          expect(rendered).not_to have_selector('.blocking #assign_general_agency')
        end
      end
    end
  end

  describe 'with modify permissions for MA' do
    before :each do
      render template: "broker_agencies/profiles/_employers.html.erb"
    end
    context "General Agency can be enabled or disabled via settings" do
      # passes in MA and DC based on Settings
      context "when disbaled", :unless => Settings.aca.general_agency_enabled do
        let(:general_agency_enabled) { false }

        it "should have general agency" do
          expect(rendered).to_not match(/General Agencies/)
        end

        it "should have button for ga assign" do
          expect(rendered).to_not have_selector('#assign_general_agency')
        end
      end
    end
  end

  describe 'without modify permissions ' do
    before :each do
      render template: "broker_agencies/profiles/_employers.html.erb"
    end

    context "when GA is enabled", :if => Settings.aca.general_agency_enabled  do
      it "should have general agency" do
        expect(rendered).to match(/General Agencies/)
      end
    end

    context "when GA is disabled" , :unless => Settings.aca.general_agency_enabled do
      it "should not have general agency" do
        expect(rendered).not_to match(/General Agencies/)
      end
      it "should not have general agency in table" do
        expect(rendered).not_to match(/General Agency/)
      end
    end
  end

end