# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Operations::ServiceAreas::Create, dbclean: :after_each do

  let(:required_params) do
    {
      active_year: 2020, issuer_provided_title: 'Title', issuer_provided_code: 'issuer_provided_code',
      issuer_profile_id: BSON::ObjectId.new, issuer_hios_id: 'issuer_hios_id',
      county_zip_ids: [{}], covered_states: [{}]
    }
  end

  context 'sending required parameters' do

    it 'should create ServiceArea' do
      expect(subject.call(service_area_params: required_params).success?).to be_truthy
      expect(subject.call(service_area_params: required_params).success.class.to_s).to match /BenefitMarkets::Entities::ServiceArea/
    end
  end
end
