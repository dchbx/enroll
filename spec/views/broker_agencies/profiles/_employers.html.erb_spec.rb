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
  describe 'with modify permissions ' do
    let(:general_agency_enabled) { true }
    before :each do
      allow(view).to receive(:general_agency_enabled?).and_return(general_agency_enabled)
      allow(view).to receive(:policy_helper).and_return(double("EmployerProfile", list_enrollments?: true, updateable?: true))
      render template: "broker_agencies/profiles/_employers.html.erb"
    end
    context "General Agency can be enabled or disabled via settings" do
      context "when enabled" do
        let(:general_agency_enabled) { true }

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
      context "when disabled" do
        let(:general_agency_enabled) { false }

        it "should have general agency" do
          expect(rendered).to_not match(/General Agencies/)
        end
        it "should have button for ga assign" do
          expect(rendered).to_not have_selector('#assign_general_agency')
        end
        it "should have checkbox for employer_profile" do
          expect(rendered).to have_selector("input[type='checkbox']")
        end
      end
    end
  end
  describe 'without modify permissions ' do
    let(:general_agency_enabled) { true }

    before :each do
      allow(view).to receive(:general_agency_enabled?).and_return(general_agency_enabled)
      allow(view).to receive(:policy_helper).and_return(double("EmployerProfile", list_enrollments?: false, updateable?: false))
      render template: "broker_agencies/profiles/_employers.html.erb"
    end

    context "when GA is enabled" do
      let(:general_agency_enabled) { true }

      it "should have general agency" do
        expect(rendered).to match(/General Agencies/)
      end

      it "should have checkbox for employer_profile" do
        expect(rendered).to have_selector("input[type='checkbox']")
      end
    end

    context "when GA is disabled" do
      let(:general_agency_enabled) { false }

      it "should not have general agency" do
        expect(rendered).not_to match(/General Agencies/)
      end
      it "should not have general agency in table" do
        expect(rendered).not_to match(/General Agency/)
      end
    end
  end
end
