# frozen_string_literal: true

RSpec.describe Operations::UpdateDobSsn, type: :model, dbclean: :after_each do
  let!(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'with correct arguments' do
    let(:test_params) do
      { person: { person_id: person.id.to_s,
                  dob: "#{TimeKeeper.date_of_record.year}-01-01",
                  ssn: '000-00-0000',
                  pid: person.id.to_s,
                  family_actions_id: 'family_actions_238764'}, jq_datepicker_ignore_person: { dob: "01/01/#{TimeKeeper.date_of_record.year}" }}
    end

    context 'success' do
      before do
        person.consumer_role.update_attributes!(active_vlp_document_id: person.consumer_role.vlp_documents.first.id)
        @result = subject.call(person_id: person.id.to_s, params: test_params, info_changed: false, dc_status: false, current_user: 'c_user', ssn_require: false)
      end

      it 'should return success' do
        expect(@result).to be_a Dry::Monads::Result::Success
      end

      it 'should return success' do
        expect(@result.success).to eq([nil, nil])
      end
    end

    context 'failure' do
      before do
        @result = subject.call(person_id: 'person_id', params: test_params, info_changed: false, dc_status: false, current_user: 'c_user', ssn_require: false)
      end

      it 'should return Failure' do
        expect(@result.failure).to eq([{person: ['Person not found']}, nil])
      end
    end
  end
end
