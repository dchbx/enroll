require 'rails_helper'

RSpec.describe PaymentTransactionsController, :type => :controller do
  let(:user){ FactoryBot.create(:user, :consumer) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent) }
  let(:primary_person) { family.primary_family_member.person }
  let(:child1) { family.family_members[1].person }
  let(:child2) { family.family_members[2].person }
  let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, aasm_state: 'shopping') }
  let(:build_saml_repsonse) {double}
  let(:encode_saml_response) {double}


  context 'GET generate saml response' do
    before(:each) do
      primary_person.person_relationships.first.update_attributes!(predecessor_id: primary_person.id, successor_id: child1.id, family_id: family.id )
      primary_person.person_relationships.last.update_attributes!(predecessor_id: primary_person.id, successor_id: child2.id, family_id: family.id )
      sign_in user
      allow_any_instance_of(OneLogin::RubySaml::SamlGenerator).to receive(:build_saml_response).and_return build_saml_repsonse
      allow_any_instance_of(OneLogin::RubySaml::SamlGenerator).to receive(:encode_saml_response).and_return encode_saml_response
    end

    it 'should generate saml response' do
      get :generate_saml_response, params: {:enrollment_id => hbx_enrollment.hbx_id}
      expect(response).to have_http_status(:success)
    end

    it 'should build payment transacations for a family' do
      get :generate_saml_response, params: {:enrollment_id => hbx_enrollment.hbx_id}
      expect(family.payment_transactions.count).to eq 1
    end

    it 'should build payment transaction with enrollment effective date and carrier id' do
      get :generate_saml_response, params: {:enrollment_id => hbx_enrollment.hbx_id}
      expect(family.payment_transactions.first.enrollment_effective_date).to eq hbx_enrollment.effective_on
      expect(family.payment_transactions.first.carrier_id).to eq hbx_enrollment.plan.carrier_profile_id
    end
  end
end
