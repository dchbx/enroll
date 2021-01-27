# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitSponsors::Operations::Organizations::Build, dbclean: :after_each do


  describe 'build organization' do

    subject do
      described_class.new.call(profile_type: profile_type, organization_attrs: organization_params)
    end

    let!(:site)  { FactoryBot.create(:benefit_sponsors_site, :with_owner_exempt_organization, :dc, :with_benefit_market) }

    let(:profile_entity) do
      BenefitSponsors::Entities::Profiles::AcaShopDcEmployerProfile.new({ office_locations: [{address: {address_1: 'dc', kind: 'primary', address_2: 'dc', city: 'dc', state: 'DC', zip: '22302'},
                                                                                                                  phone: {kind: 'work', area_code: '893', number: '8302840'}}],
                                                                          contact_method: :electronic_only
                                                                        })
      end
    
    let(:organization_params) do
      {
        entity_kind: 'tax_exempt_organization',
        legal_name: 'Test',
        dba: '',
        fein: '123456789',
        profiles: [profile_entity]
      }
    end

    context 'profile type benefit_sponsor' do
      let(:profile_type) { 'benefit_sponsor' }

      it 'should be success' do
        expect(subject.success?).to be_truthy
      end

      it 'should build organization object' do
        expect(subject.success).to be_a ::BenefitSponsors::Entities::Organizations::GeneralOrganization
      end
    end

    context 'profile type broker_agency' do
      let(:profile_type) { 'broker_agency' }

      it 'should be success' do
        expect(subject.success?).to be_truthy
      end

      it 'should build organization object' do
        expect(subject.success).to be_a ::BenefitSponsors::Entities::Organizations::ExemptOrganization
      end
    end

    context 'profile type general_agency' do
      let(:profile_type) { 'general_agency' }

      it 'should be success' do
        expect(subject.success?).to be_truthy
      end

      it 'should build organization object' do
        expect(subject.success).to be_a ::BenefitSponsors::Entities::Organizations::GeneralOrganization
      end
    end
  end
end
