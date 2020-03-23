# frozen_string_literal: true

RSpec.describe Operations::ValidateVlpDocument, type: :model, dbclean: :after_each do
  let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'Immigration status' do
    let(:immigration_type) { FactoryBot.build(:verification_type, type_name: 'Immigration status') }

    before :each do
      person.verification_types = [immigration_type]
      person.save!
      person.consumer_role.vlp_documents = [i327_vlp_document]
      person.consumer_role.update_attributes!(aasm_state: 'verification_outstanding', active_vlp_document_id: i327_vlp_document.id)
      person.consumer_role.save!
    end

    context 'success call' do
      let(:i327_vlp_document) { FactoryBot.build(:vlp_document) }

      it 'should call the hub with success message' do
        result = subject.call(person_id: person.id)
        expect(result.success).to eq(person)
      end
    end

    context 'failure case' do
      let(:i327_vlp_document) { FactoryBot.build(:vlp_document, subject: 'Other (With Alien Number)') }

      it 'should not call the hub with failure message' do
        result = subject.call(person_id: person.id)
        expect(result.failure).to eq('Please fill in your information for Document Description.')
      end
    end
  end
end
