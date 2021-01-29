# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::GenerateSamlResponse do

  let!(:person) {FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
  let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:household) {family.active_household}
  let!(:primary_fm) {family.primary_applicant}
  let(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01')}
  let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, aasm_state: 'shopping', product: product) }
  let(:build_saml_repsonse) {double}
  let(:encode_saml_response) {double}
  let(:connection) {double}
  let(:params) do 
    {:enrollment_id => hbx_enrollment.hbx_id }
  end

  before do
    allow(HTTParty).to receive(:post).and_return connection
    allow_any_instance_of(OneLogin::RubySaml::SamlGenerator).to receive(:build_saml_response).and_return build_saml_repsonse
    allow_any_instance_of(OneLogin::RubySaml::SamlGenerator).to receive(:encode_saml_response).and_return encode_saml_response
  end
  
  subject do
    described_class.new.call(params)
  end

  describe "Not passing params to call the operation" do
    let(:params) { { } }

    it "fails" do
      expect(subject).not_to be_success
      expect(subject.failure).to eq "Given input is not a valid enrollment id"
    end
  end

  describe "passing correct params to call the operation" do
    it "Passes" do
      expect(subject).to be_success
      expect(subject.success.key?(:SAMLResponse)).to be_truthy
    end
  end
end

