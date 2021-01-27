# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitSponsors::Operations::Profiles::Build, dbclean: :after_each do


  describe 'build profile' do

    subject do
      described_class.new.call(profile_type: profile_type, profile_attrs: profile_params)
    end

    let(:profile_params) do
      {:office_locations=>
         [{:address => {address_1: 'dc', kind: 'primary', address_2: 'dc', city: 'dc', state: 'DC', zip: '22302'},
           :phone => {kind: 'work', area_code: '893', number: '8302840'}}],
       :contact_method => 'electronic_only'}
    end

    context 'profile type benefit_sponsor' do
      let(:profile_type) { 'benefit_sponsor' }

      it 'should be success' do
        expect(subject.success?).to be_truthy
      end

      it 'should build organization object' do
        expect(subject.success).to be_a BenefitSponsors::Entities::Profiles::AcaShopDcEmployerProfile
      end
    end

    context 'profile type broker_agency' do
      let(:profile_type) { 'broker_agency' }
      let(:profile_params) do
        {:office_locations=>
           [{:address => {address_1: 'dc', kind: 'primary', address_2: 'dc', city: 'dc', state: 'DC', zip: '22302'},
             :phone => {kind: 'work', area_code: '893', number: '8302840'}}],
         :contact_method => 'electronic_only',
        :market_kind => 'individual_only'}
      end

      it 'should be success' do
        expect(subject.success?).to be_truthy
      end

      it 'should build organization object' do
        expect(subject.success).to be_a BenefitSponsors::Entities::Profiles::BrokerAgencyProfile
      end
    end

    context 'profile type general_agency' do
      let(:profile_type) { 'general_agency' }
      let(:profile_params) do
        {:office_locations=>
           [{:address => {address_1: 'dc', kind: 'primary', address_2: 'dc', city: 'dc', state: 'DC', zip: '22302'},
             :phone => {kind: 'work', area_code: '893', number: '8302840'}}],
         :contact_method => 'electronic_only',
         :market_kind => 'individual_only'}
      end

      it 'should be success' do
        expect(subject.success?).to be_truthy
      end

      it 'should build organization object' do
        expect(subject.success).to be_a BenefitSponsors::Entities::Profiles::GeneralAgencyProfile
      end
    end
  end
end
