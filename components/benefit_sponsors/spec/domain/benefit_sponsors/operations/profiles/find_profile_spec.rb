# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitSponsors::Operations::Profiles::FindProfile, dbclean: :after_each do

  let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key) }
  let(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_dc_employer_profile, site: site)}
  let(:employer_profile) {organization.employer_profile}

  describe 'find profile' do
    let(:valid_params) { {profile_id: employer_profile.id} }
    let(:invalid_params) { {profile_id: organization.id} }

    it 'should return ER profile' do
      result = subject.call(valid_params)

      expect(result.success?). to be_truthy
      expect(result.success). to be_a BenefitSponsors::Organizations::AcaShopDcEmployerProfile
    end

    it 'should throw an error' do
      result = subject.call(invalid_params)

      expect(result.success?). to be_falsey
      expect(result.failure[:message]). to eq(["Profile not found"])
    end
  end
end
