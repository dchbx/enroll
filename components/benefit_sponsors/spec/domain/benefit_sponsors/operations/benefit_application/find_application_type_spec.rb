# frozen_string_literal: true

require "rails_helper"
require File.join(File.dirname(__FILE__), "..", "..", "..", "..", "support/benefit_sponsors_site_spec_helpers")
# require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe BenefitSponsors::Operations::BenefitApplication::FindApplicationType, dbclean: :after_each do

  let(:site)                    { ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_benefit_market }
  let!(:benefit_market)         { site.benefit_markets.first }
  let!(:organization)           { FactoryBot.create(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym, site: site) }
  let(:benefit_sponsorship)     { organization.employer_profile.add_benefit_sponsorship }
  let!(:benefit_application) do
    FactoryBot.create(:benefit_sponsors_benefit_application,
                      :with_benefit_package,
                      :benefit_sponsorship => benefit_sponsorship,
                      :aasm_state => 'active')
  end

  let(:params)          { {benefit_application_id: benefit_application.id} }

  context 'sending required parameters' do

    it 'should be success' do
      expect(subject.call(params).success?).to be_truthy
    end

    it 'should return value' do
      expect(subject.call(params).success).to eq 'initial'
    end
  end
end
