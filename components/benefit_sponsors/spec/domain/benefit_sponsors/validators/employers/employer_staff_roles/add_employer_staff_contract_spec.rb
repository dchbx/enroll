# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitSponsors::Validators::Employers::EmployerStaffRoles::AddEmployerStaffContract do

  let(:missing_params)   { {first_name: 'male', last_name: 'test', coverage_record: { is_applying_coverage: false, address: {}, email: {}}} }
  let(:error_message)    do
    {
      :profile_id => ["is missing"],
      :person_id => ["is missing"],
      :dob => ["is missing"]
    }
  end

  describe "Given invalid required parameters" do
    context "sending with missing parameters should fail validation with errors" do
      it { expect(subject.call(missing_params).failure?).to be_truthy }
      it { expect(subject.call(missing_params).errors.to_h).to eq error_message }
    end
  end

  describe "Given valid parameters" do
    let(:valid_params) { missing_params.merge({profile_id: '12345', person_id: '12345', dob: TimeKeeper.date_of_record})}

    context "with required params" do
      it "should pass validation" do
        expect(subject.call(valid_params).success?).to be_truthy
        expect(subject.call(valid_params).to_h).to eq valid_params
      end
    end
  end
end
