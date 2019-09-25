# frozen_string_literal: true

require 'rails_helper'

describe "shared/_carrier_contact_information_#{Settings.aca.state_abbreviation.downcase}.html.erb", dbclean: :after_each do
  let(:plan) do
    double(
      'Product',
      id: "122455",
      issuer_profile: issuer_profile
    )
  end

  let(:issuer_profile) { double("IssuerProfile") }

  context 'for Delta Dental' do
    before :each do
      allow(plan).to receive(:kind).and_return('dental')
      allow(issuer_profile).to receive(:legal_name).and_return('Delta Dental')
      render partial: "shared/carrier_contact_information_#{Settings.aca.state_abbreviation.downcase}", locals: { plan: plan }
    end

    it "should display the carrier name and number" do
      expect(rendered).to match issuer_profile.legal_name
      expect(rendered).to match("1-800-471-0236")
    end
  end

  context 'for Aetna' do
    before :each do
      allow(plan).to receive(:kind).and_return('health')
      allow(issuer_profile).to receive(:legal_name).and_return('Aetna')
      render partial: "shared/carrier_contact_information_#{Settings.aca.state_abbreviation.downcase}", locals: { plan: plan }
    end

    it "should display the carrier name and number" do
      expect(rendered).to match issuer_profile.legal_name
      expect(rendered).to match("1-855-319-7290")
      expect(rendered).to match("from 8am-5pm EST, Monday - Friday")
    end
  end
end
