# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitSponsors::Operations::GeneralAgencies::Forms::NewGeneralAgencyStaff, dbclean: :after_each do

  let(:person) {FactoryBot.create(:person)}
  let(:params) { {id: person.id}}

  context 'for failure case' do
    it 'should fail if person not found with given id' do
      result = subject.call({})
      expect(result.failure).to eq({:message => ['person_id is expected']})
    end

  end

  context 'for success case' do
    it 'should return new ga staff entity' do
      result = subject.call(params)
      expect(result.value!).to be_a BenefitSponsors::Entities::Forms::GeneralAgencies::GeneralAgencyStaffRoles::New
    end
  end
end
