require 'rails_helper'

describe "shared/_#{Settings.aca.state_abbreviation.downcase}_carrier_contact_information.html.erb", dbclean: :after_each do
  let(:plan) {
    double('Product',
      id: "122455",
      issuer_profile: issuer_profile
      )
  }

  let(:issuer_profile){
    double("IssuerProfile")
  }

  let!(:person)          { FactoryBot.create(:person, :with_consumer_role) }
  let!(:family)          { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let!(:hbx_enrollment)  { FactoryBot.create(:hbx_enrollment, household: family.active_household, family: family) }

  context 'for BMC HealthNet Plan' do
    before :each do
      allow(plan).to receive(:kind).and_return('health')
      allow(issuer_profile).to receive(:legal_name).and_return('BMC HealthNet Plan')
      render partial: "shared/carrier_contact_information", locals: { plan: plan, hbx_enrollment: hbx_enrollment }
    end

    it "should display the carrier name and number" do
      expect(rendered).to match issuer_profile.legal_name
      expect(rendered).to match("855-833-8120")
      expect(rendered).to match("memberquestions@bmchp.org")
      expect(rendered).to match("Monday through Friday from 8:00 a.m. to 6:00 p.m.")
    end
  end

  context 'for Fallon Health' do
    before :each do
      allow(plan).to receive(:kind).and_return('health')
      allow(issuer_profile).to receive(:legal_name).and_return('Fallon Health')
      render partial: "shared/carrier_contact_information", locals: { plan: plan, hbx_enrollment: hbx_enrollment }
    end

    it "should display the carrier name and number" do
      expect(rendered).to match issuer_profile.legal_name
      expect(rendered).to match("800-868-5200")
      expect(rendered).to match("FCHPcustomerservice@fallonhealth.org")
      expect(rendered).to match("Monday, Tuesday, Thursday, and Friday from 8:00 a.m. to 6:00 p.m., and Wednesday from 10:00 a.m. to 6:00 p.m.")
    end
  end

  context 'for Health New England' do
    before :each do
      allow(plan).to receive(:kind).and_return('health')
      allow(issuer_profile).to receive(:legal_name).and_return('Health New England')
      render partial: "shared/carrier_contact_information", locals: { plan: plan, hbx_enrollment: hbx_enrollment }
    end

    it "should display the carrier name and number" do
      expect(rendered).to match issuer_profile.legal_name
      expect(rendered).to match("413-787-4004")
      expect(rendered).to match("memberservices@hne.com")
      expect(rendered).to match("Monday through Friday, 8:00 a.m. to 6:00 p.m.")
    end
  end

  context 'for United Healthcare' do
    before :each do
      allow(plan).to receive(:kind).and_return('health')
      allow(issuer_profile).to receive(:legal_name).and_return('United Healthcare')
      render partial: "shared/carrier_contact_information", locals: { plan: plan, hbx_enrollment: hbx_enrollment }
    end

    it "should display the carrier name and number" do
      expect(rendered).to match issuer_profile.legal_name
      expect(rendered).to match("1-888-842-4571")
      expect(rendered).to match("7 AM to 6 PM CST")
    end
  end

  context 'for Harvard Pilgrim Health Care' do
    before :each do
      allow(plan).to receive(:kind).and_return('health')
      allow(issuer_profile).to receive(:legal_name).and_return('Harvard Pilgrim Health Care')
      render partial: "shared/carrier_contact_information", locals: { plan: plan, hbx_enrollment: hbx_enrollment }
    end

    it "should display the carrier name and number" do
      expect(rendered).to match issuer_profile.legal_name
      expect(rendered).to match("888-333-4742")
      expect(rendered).to match("send secure email after login to member account")
      expect(rendered).to match("Monday, Tuesday, & Thursday from 8:00 a.m. to 6:00 p.m.; Wednesday from 10:00 a.m. to 6:00 p.m.; and Friday from 8:00 a.m. to 5:30 p.m")
    end
  end

  context 'for AllWays Health Partners' do
    before :each do
      allow(plan).to receive(:kind).and_return('health')
      allow(issuer_profile).to receive(:legal_name).and_return('AllWays Health Partners')
      render partial: "shared/carrier_contact_information", locals: { plan: plan, hbx_enrollment: hbx_enrollment }
    end

    it "should display the carrier name and number" do
      expect(rendered).to match issuer_profile.legal_name
      expect(rendered).to match("866-414-5533")
      expect(rendered).to match("customerservice@AllWaysHealth.org")
      expect(rendered).to match("Monday, Tuesday, Wednesday, Friday from 8:00 a.m. to 6:00 p.m.; Thursday from 8:00 a.m. to 8:00 p.m.")
    end
  end

  context 'for Altus Dental' do
    before :each do
      allow(plan).to receive(:kind).and_return('Dental')
      allow(issuer_profile).to receive(:legal_name).and_return('Altus Dental')
      render partial: "shared/carrier_contact_information", locals: { plan: plan, hbx_enrollment: hbx_enrollment }
    end

    it "should display the carrier name and number" do
      expect(rendered).to match issuer_profile.legal_name
      expect(rendered).to match("1.877.223.0588")
      expect(rendered).to match("customerservice@altusdental.com")
      expect(rendered).to match("Monday - Thursday, 8 am to 7 pm and Friday 8 am to 5 pm, ET.")
    end
  end

  context 'for Delta Dental' do
    before :each do
      allow(plan).to receive(:kind).and_return('Dental')
      allow(issuer_profile).to receive(:legal_name).and_return('Delta Dental')
      render partial: "shared/carrier_contact_information", locals: { plan: plan, hbx_enrollment: hbx_enrollment }
    end

    it "should display the carrier name and number" do
      expect(rendered).to match issuer_profile.legal_name
      expect(rendered).to match("800.872.0500")
      expect(rendered).to match("customer.care@deltadentalma.com")
      expect(rendered).to match("Monday - Thursday, 8:30 a.m. to 8:00 p.m. EST; Friday, 8:30 a.m. to 4:30 p.m. EST")
    end
  end
end
