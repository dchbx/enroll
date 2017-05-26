require 'rails_helper'
require File.join(Rails.root, "spec", "support", "acapi_vocabulary_spec_helpers")

RSpec.describe "events/v2/employer/updated.haml.erb" do
  let(:entity_kind)     { "partnership" }
  let(:bad_entity_kind) { "fraternity" }
  let(:entity_kind_error_message) { "#{bad_entity_kind} is not a valid business entity kind" }

  let(:address)  { Address.new(kind: "primary", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002") }
  let(:phone  )  { Phone.new(kind: "main", area_code: "202", number: "555-9999") }
  let(:mailing_address)  { Address.new(kind: "mailing", address_1: "609", city: "Washington", state: "DC", zip: "20002") }
  let(:email  )  { Email.new(kind: "work", address: "info@sailaway.org") }

  let(:office_location) { OfficeLocation.new(
      is_primary: true,
      address: address,
      phone: phone
  )
  }

  let(:office_location2) { OfficeLocation.new(
      is_primary: false,
      address: mailing_address
  )
  }

  let(:organization) { Organization.create(
      legal_name: "Sail Adventures, Inc",
      dba: "Sail Away",
      fein: "001223333",
      office_locations: [office_location,office_location2]
  )
  }

  let(:valid_params) do
    {
        organization: organization,
        entity_kind: entity_kind,
        profile_source: 'self_serve',
        created_at: Date.today
    }
  end


  describe "given a employer" do
    let(:benefit_group)     { FactoryGirl.build(:benefit_group)}
    let(:plan_year)         { FactoryGirl.build(:plan_year, benefit_groups: [benefit_group], aasm_state:'published',
                  created_at: Date.new)}
    let!(:employer)  { EmployerProfile.new(**valid_params, plan_years: [plan_year]) }

    let(:staff) { FactoryGirl.create(:person, :with_work_email, :with_work_phone)}
    let(:broker_agency_profile) { BrokerAgencyProfile.create(market_kind: "both") }
    let(:person_broker) {FactoryGirl.build(:person,:with_work_email, :with_work_phone)}
    let(:broker) {FactoryGirl.build(:broker_role,aasm_state:'active',person:person_broker)}
    include AcapiVocabularySpecHelpers

    before(:all) do
      download_vocabularies
    end

    #let(:plan_year) { PlanYear.new(:aasm_state => "published", :created_at => DateTime.now, :start_on => DateTime.now, :open_enrollment_start_on => DateTime.now, :open_enrollment_end_on => DateTime.now) }


    before :each do
      allow(employer).to receive(:staff_roles).and_return([staff])
      allow(employer).to receive(:broker_agency_profile).and_return(broker_agency_profile)
      allow(broker_agency_profile).to receive(:brokers).and_return([broker])
      allow(broker_agency_profile).to receive(:primary_broker_role).and_return(broker)
      render :template => "events/v2/employers/updated", :locals => { :employer => employer }
      @doc = Nokogiri::XML(rendered)
    end

    it "should have one plan year" do
      expect(@doc.xpath("//x:plan_years/x:plan_year", "x"=>"http://openhbx.org/api/terms/1.0").count).to eq 1
    end

    it "should have two office_location" do
      expect(@doc.xpath("//x:office_location", "x"=>"http://openhbx.org/api/terms/1.0").count).to eq 2
    end

    it "should have office location with address kind work" do
      expect(@doc.xpath("//x:office_locations/x:office_location[1]/x:address/x:type","x"=>"http://openhbx.org/api/terms/1.0").text).to eq "urn:openhbx:terms:v1:address_type#work"
    end

    it "should have office location with address kind mailing" do
      expect(@doc.xpath("//x:office_locations/x:office_location[2]/x:address/x:type","x"=>"http://openhbx.org/api/terms/1.0").text).to eq "urn:openhbx:terms:v1:address_type#mailing"
    end

    it "should not have phone for mailing office location " do
      expect(@doc.xpath("//x:office_location[2]/x:phone", "x"=>"http://openhbx.org/api/terms/1.0").to_a).to eq []
    end

    it "should have one broker_agency_profile" do
      expect(@doc.xpath("//x:broker_agency_profile", "x"=>"http://openhbx.org/api/terms/1.0").count).to eq 1
    end

    it "should have brokers in broker_agency_profile" do
      expect(@doc.xpath("//x:broker_agency_profile/x:brokers", "x"=>"http://openhbx.org/api/terms/1.0").count).to eq 1
    end

    it "should have contact email" do
      expect(@doc.xpath("//x:contacts/x:contact//x:emails//x:email//x:email_address", "x"=>"http://openhbx.org/api/terms/1.0").text).to eq staff.work_email_or_best
    end

    it "should not have shop_transfer" do
      expect(@doc.xpath("//x:shop_transfer/x:hbx_active_on", "x"=>"http://openhbx.org/api/terms/1.0").text).to eq ""
    end


    it "should be schema valid" do
      expect(validate_with_schema(Nokogiri::XML(rendered))).to eq []
    end

    context "with dental plans" do

      context "is_offering_dental? is true" do

        before do
          dental_plan = FactoryGirl.create(:plan, name: "new dental plan", coverage_kind: 'dental',
                                           dental_level: 'high')
          benefit_group.elected_dental_plans = [dental_plan]
          benefit_group.dental_reference_plan_id = dental_plan.id
          plan_year.save!
        end

        it "shows the dental plan in output" do
          render :template => "events/v2/employers/updated", :locals => {:employer => employer}
          expect(rendered).to include "new dental plan"
        end
      end


      context "is_offering_dental? is false" do
        before do
          benefit_group.dental_reference_plan_id = nil
          benefit_group.save!
        end

        it "does not show the dental plan in output" do

          render :template => "events/v2/employers/updated", :locals => {:employer => employer}
          expect(rendered).not_to include "new dental plan"
        end
      end
    end

    context "person of contact" do
      it "should be included in xml" do
        expect(rendered).to have_selector('contact', count: 1)
      end
    end

  end
end
