# frozen_string_literal: true

require "rails_helper"
require File.join(File.dirname(__FILE__), "..", "..", "..", "..", "support/benefit_sponsors_site_spec_helpers")
# require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe BenefitSponsors::Operations::CobraEnrollmentEligibility::Determine, dbclean: :after_each do

  let(:site)                    { ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_benefit_market }
  let!(:benefit_market)         { site.benefit_markets.first }
  let!(:organization)           { FactoryBot.create(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym, site: site) }
  let(:benefit_sponsorship)     { organization.employer_profile.add_benefit_sponsorship }

  let!(:benefit_application) do
    FactoryBot.create(:benefit_sponsors_benefit_application,
                      :with_benefit_package,
                      :benefit_sponsorship => benefit_sponsorship,
                      :aasm_state => 'active',
                      :effective_period => start_on..start_on.next_year.prev_day)
  end

  let(:params)          { {effective_date: start_on, benefit_application_id: benefit_application.id} }

  context 'sending required parameters' do

    context 'for employers with effective date on or after 8/1' do

      let(:start_on)                { Date.new(2020, 8, 1) } #had to hard code the dates because this feature is expected to be valid from 2020/7/1 to 2020/12/31(subject to change)

      it 'should be success' do
        expect(subject.call(params).success?).to be_truthy
      end

      it 'should return value' do
        expect(subject.call(params).success).to be_truthy
      end
    end

    context 'for employers with effective date before 7/1' do

      let(:start_on)                { Date.new(2020, 6, 1) } #had to hard code the dates because this feature is expected to be valid from 2020/7/1 to 2020/12/31(subject to change)

      it 'should be success' do
        expect(subject.call(params).success?).to be_truthy
      end

      it 'should return value' do
        expect(subject.call(params).success).to be_falsey
      end
    end

  end
end
