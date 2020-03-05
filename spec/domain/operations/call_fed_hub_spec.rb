# frozen_string_literal: true

RSpec.describe Operations::CallFedHub, type: :model, dbclean: :after_each do
  let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'invalid arguments' do
    it 'should return a failure' do
      result = subject.call(person_id: 'person_id', verification_type: 'verification_type')
      expect(result.failure).to eq([:danger, 'Person not found'])
    end
  end

  context 'DC Residency' do
    let(:dc_type) { FactoryBot.build(:verification_type, type_name: 'DC Residency') }

    before :each do
      person.verification_types = [dc_type]
      person.consumer_role.update_attributes!(aasm_state: 'verification_outstanding')
      person.consumer_role.save!
    end

    it 'should success for DC Residency' do
      result = subject.call(person_id: person.id, verification_type: dc_type.type_name)
      expect(result.success).to eq([:success, "Request was sent to Local Residency."])
    end
  end

  context 'Immigration status' do
    let(:immigration_type) { FactoryBot.build(:verification_type, type_name: 'Immigration status') }

    before :each do
      person.verification_types = [immigration_type]
      person.save!
      person.consumer_role.vlp_documents = [i327_vlp_document]
      person.consumer_role.update_attributes!(aasm_state: 'verification_outstanding')
      person.consumer_role.save!
    end

    context 'success call' do
      let(:i327_vlp_document) { FactoryBot.build(:vlp_document) }

      it 'should call the hub with success message' do
        result = subject.call(person_id: person.id, verification_type: immigration_type.type_name)
        expect(result.success).to eq([:success, 'Request was sent to FedHub.'])
      end
    end

    context 'failure case' do
      let(:i327_vlp_document) { FactoryBot.build(:vlp_document, subject: 'Other (With Alien Number)') }

      it 'should not call the hub with failure message' do
        result = subject.call(person_id: person.id, verification_type: immigration_type.type_name)
        expect(result.failure).to eq([:danger, 'Please fill in your information for Description'])
      end
    end
  end

  context 'for Invalid VLP Document type' do
    let(:immigration_type) { FactoryBot.build(:verification_type, type_name: 'Immigration status') }

    before :each do
      person.verification_types = [immigration_type]
      person.save!
      person.consumer_role.vlp_documents = [bad_vlp_document]
      person.consumer_role.update_attributes!(aasm_state: 'verification_outstanding')
      person.consumer_role.save!
    end

    context 'failure case' do
      let(:bad_vlp_document) { FactoryBot.build(:vlp_document, subject: 'test') }

      it 'should not call the hub with failure message' do
        result = subject.call(person_id: person.id, verification_type: immigration_type.type_name)
        expect(result.failure).to eq([:danger, 'VLP document type is invalid: test'])
      end
    end
  end
end
