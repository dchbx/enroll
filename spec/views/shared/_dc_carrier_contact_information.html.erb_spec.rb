# frozen_string_literal: true

require 'rails_helper'

describe "shared/_#{Settings.aca.state_abbreviation.downcase}_carrier_contact_information.html.erb", dbclean: :after_each do
  let(:plan) do
    double('Product',
           id: "122455",
           issuer_profile: issuer_profile)
  end

  let(:issuer_profile) do
    double("IssuerProfile")
  end

  let!(:person)          { FactoryBot.create(:person, :with_consumer_role) }
  let!(:family)          { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let!(:hbx_enrollment)  { FactoryBot.create(:hbx_enrollment, household: family.active_household, family: family) }

  context 'for UnitedHealthcare' do
    before :each do
      allow(plan).to receive(:kind).and_return('health')
      allow(issuer_profile).to receive(:legal_name).and_return('UnitedHealthcare')
      render partial: "shared/#{Settings.aca.state_abbreviation.downcase}_carrier_contact_information", locals: { plan: plan, hbx_enrollment: hbx_enrollment }
    end

    it "should display the carrier name and number" do
      expect(rendered).to match issuer_profile.legal_name
      expect(rendered).to match("1-877-856-2430")
    end
  end

  context 'for CareFirst' do
    before :each do
      allow(plan).to receive(:kind).and_return('health')
      allow(issuer_profile).to receive(:legal_name).and_return('CareFirst BCBS')
      render partial: "shared/#{Settings.aca.state_abbreviation.downcase}_carrier_contact_information", locals: { plan: plan, hbx_enrollment: hbx_enrollment }
    end

    it "should display the carrier name and number" do
      expect(rendered).to match issuer_profile.legal_name
      expect(rendered).to match("1-855-444-3121")
      expect(rendered).to match("Note: Congressional Employees may also contact Carefirst at 1-855-541-3985.")
    end
  end

  context 'for Aetna' do
    before :each do
      allow(plan).to receive(:kind).and_return('health')
      allow(issuer_profile).to receive(:legal_name).and_return('Aetna')
      render partial: "shared/#{Settings.aca.state_abbreviation.downcase}_carrier_contact_information", locals: { plan: plan, hbx_enrollment: hbx_enrollment }
    end

    it "should display the carrier name and number" do
      expect(rendered).to match issuer_profile.legal_name
      expect(rendered).to match("1-855-586-6959")
      expect(rendered).to match("1-855-319-7290")
    end
  end

  context 'for Kaiser' do
    before :each do
      allow(plan).to receive(:kind).and_return('health')
      allow(issuer_profile).to receive(:legal_name).and_return('Kaiser')
      render partial: "shared/#{Settings.aca.state_abbreviation.downcase}_carrier_contact_information", locals: { plan: plan, hbx_enrollment: hbx_enrollment }
    end

    it "should display the carrier name and number" do
      expect(rendered).to match issuer_profile.legal_name
      expect(rendered).to match("1-800-777-7902")
    end
  end

  context 'for Delta Dental' do
    before :each do
      allow(plan).to receive(:kind).and_return('Dental')
      allow(issuer_profile).to receive(:legal_name).and_return('Delta Dental')
      render partial: "shared/#{Settings.aca.state_abbreviation.downcase}_carrier_contact_information", locals: { plan: plan, hbx_enrollment: hbx_enrollment }
    end

    it "should display the carrier name and number" do
      expect(rendered).to match issuer_profile.legal_name
      expect(rendered).to match("1-800-471-0236")
      expect(rendered).to match("1-800-471-0275")
    end
  end

  context 'for Dominion National' do
    before :each do
      allow(plan).to receive(:kind).and_return('Dental')
      allow(issuer_profile).to receive(:legal_name).and_return('Dominion National')
      render partial: "shared/#{Settings.aca.state_abbreviation.downcase}_carrier_contact_information", locals: { plan: plan, hbx_enrollment: hbx_enrollment }
    end

    it "should display the carrier name and number" do
      expect(rendered).to match issuer_profile.legal_name
      expect(rendered).to match("1-855-224-3016")
    end
  end

  context 'for BEST Life' do
    before :each do
      allow(plan).to receive(:kind).and_return('Dental')
      allow(issuer_profile).to receive(:legal_name).and_return('BEST Life')
      render partial: "shared/#{Settings.aca.state_abbreviation.downcase}_carrier_contact_information", locals: { plan: plan, hbx_enrollment: hbx_enrollment }
    end

    it "should display the carrier name and number" do
      expect(rendered).to match issuer_profile.legal_name
      expect(rendered).to match("1-800-433-0088")
    end
  end
end
