# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitSponsors::Validators::GeneralAgencies::GeneralAgencyStaffRoles::AddGeneralAgencyStaffRoleContract do

  let(:missing_params)   { {first_name: 'test', last_name: 'test', dob: TimeKeeper.date_of_record} }
  let(:error_message)    { {:person_id => ['is missing'], :profile_id => ['is missing']} }

  describe 'Given invalid required parameters' do
    context 'sending with missing parameters should fail validation with errors' do
      it { expect(subject.call(missing_params).failure?).to be_truthy }
      it { expect(subject.call(missing_params).errors.to_h).to eq error_message }
    end
  end

  describe 'Given valid parameters' do
    let(:valid_params) { missing_params.merge({email: 'test@dc.gov', person_id: '12345', profile_id: '12345'})}

    context 'with required params' do
      it 'should pass validation' do
        expect(subject.call(valid_params).success?).to be_truthy
        expect(subject.call(valid_params).to_h).to eq valid_params
      end
    end
  end
end
