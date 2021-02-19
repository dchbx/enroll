# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitSponsors::Validators::Organizations::OrganizationForms::StaffRoleFormContract do

  let(:params) do
    {
      first_name: 'test', last_name: 'test',
      dob: "01/01/1988"
    }
  end


  let(:error_message)    { {:email => ["is missing"], :profile_type => ["is missing"]} }

  describe "Given invalid required parameters" do
    context "sending with missing parameters should fail validation with errors" do
      it { expect(subject.call(params).failure?).to be_truthy }
      it { expect(subject.call(params).errors.to_h).to eq error_message }
    end

    context 'sending missing parameters if profile is broker agency or general agency' do
      it 'should throw an error if broker agency' do
        missing_params = params.merge({:profile_type => 'broker_agency', email: 'test@test.com'})
        expect(subject.call(missing_params).failure?).to be_truthy
        expect(subject.call(missing_params).errors.to_h).to eq({:npn => ["Please enter NPN"]})
      end

      it 'should throw an error if general agency' do
        missing_params = params.merge({:profile_type => 'general_agency', email: 'test@test.com'})
        expect(subject.call(missing_params).failure?).to be_truthy
        expect(subject.call(missing_params).errors.to_h).to eq({:npn => ["Please enter NPN"]})
      end
    end
  end

  describe "Given valid parameters" do
    let(:valid_params) { params.merge({profile_type: 'benefit_sponsor', email: 'test@test.com'})}

    context "with required params" do
      it "should pass validation" do
        expect(subject.call(valid_params).success?).to be_truthy
        expect(subject.call(valid_params).to_h).to eq valid_params
      end
    end
  end
end
