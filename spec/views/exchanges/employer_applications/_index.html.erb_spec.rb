# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe "exchanges/employer_applications/index.html.erb", dbclean: :after_each do

  include_context "setup benefit market with market catalogs and product packages"

  let(:family) { FactoryBot.create(:family, :with_primary_family_member,person: person) }
  let(:user) { FactoryBot.create(:user, person: person, roles: ["hbx_staff"]) }
  let(:person) { FactoryBot.create(:person) }

  context 'When employer has valid plan years' do

    include_context "setup initial benefit application"

    let(:employer_profile) { benefit_sponsorship.profile }

    before :each do
      sign_in(user)
      assign :employer_profile, employer_profile
      assign :benefit_sponsorship, benefit_sponsorship
      initial_application.update_attributes!(aasm_state: :terminated)
      render "exchanges/employer_applications/index", employers_action_id: "employers_action_#{employer_profile.id}", employer_id: benefit_sponsorship
    end

    it 'should have title' do
      expect(rendered).to have_content('Applications')
    end

    it "should have plan year aasm_state" do
      expect(rendered).to match(/#{initial_application.aasm_state}/)
    end

    it "should have plan year start date" do
      expect(rendered).to match(/#{initial_application.start_on}/)
    end

    it "should have cancel, terminate, reinstate links" do
      allow(::EnrollRegistry).to receive(:feature_enabled?).with(:benefit_application_reinstate).and_return(true)
      expect(rendered).to match(/cancel/)
      expect(rendered).to match(/terminate/)
      expect(rendered).to match(/reinstate/)
    end
  end

  context 'When a plan year is selected' do

    include_context "setup initial benefit application"

    let(:employer_profile) { benefit_sponsorship.profile }

    before :each do
      sign_in(user)
      assign :employer_profile, employer_profile
      assign :benefit_sponsorship, benefit_sponsorship
      render "exchanges/employer_applications/index", employers_action_id: "employers_action_#{employer_profile.id}", employer_id: benefit_sponsorship
    end

    it 'should display termination reasons' do
      expect(rendered).to have_content('Please select terminate reason') if show_termination_reasons?
    end
  end

  context 'When employer doesnt have valid plan years' do

    let!(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:benefit_sponsorship) do
      FactoryBot.create(
        :benefit_sponsors_benefit_sponsorship,
        :with_rating_area,
        :with_service_areas,
        supplied_rating_area: current_rating_area,
        service_area_list: [service_area],
        organization: organization,
        profile_id: organization.profiles.first.id,
        benefit_market: benefit_market,
        employer_attestation: employer_attestation
      )
    end
    let!(:employer_attestation)     { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }

    before :each do
      sign_in(user)
      assign :employer_profile, benefit_sponsorship.profile
      assign :benefit_sponsorship, benefit_sponsorship
      render "exchanges/employer_applications/index", employers_action_id: "employers_action_#{benefit_sponsorship.profile.id}", employer_id: benefit_sponsorship
    end

    it 'should have title' do
      expect(rendered).to have_content('Applications')
    end

    it "should have not cancel, terminate, reinstate links" do
      expect(rendered).not_to match(/cancel/)
      expect(rendered).not_to match(/terminate/)
      expect(rendered).not_to match(/Reinstate/)
    end
  end
end