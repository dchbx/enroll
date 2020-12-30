# frozen_string_literal: true

require "rails_helper"

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  describe Subscribers::LocalResidency do
    extend ::Config::AcaHelper

    it 'should subscribe to the correct event' do
      expect(Subscribers::LocalResidency.subscription_details).to eq ['acapi.info.events.residency.verification_response']
    end

    describe 'given a residency verification message to handle' do
      let(:individual_id) { '121211' }
      let(:xml) { File.read(Rails.root.join('spec', 'test_data', 'residency_verification_payloads', 'response.xml')) }
      let(:xml_hash) { {residency_verification_response: 'ADDRESS_NOT_IN_AREA'} }
      let(:xml_hash2) { {residency_verification_response: 'ADDRESS_IN_AREA'} }
      let(:person) { FactoryBot.create(:person, :with_consumer_role) }
      let(:consumer_role) { person.consumer_role }
      let(:history_elements_DC) {consumer_role.verification_types.by_name('DC Residency').first.type_history_elements}

      let(:payload) { {:individual_id => individual_id, :body => xml} }

      context 'stores Local Hub response in verification history' do
        it 'stores verification history element' do
          person.verification_types.each{|type| type.type_history_elements.delete_all }
          allow(subject).to receive(:find_person).with(individual_id).and_return(person)
          subject.call(nil, nil, nil, nil, payload)
          expect(history_elements_DC.count).to be > 0
        end

        it 'stores verification history element for right verification type' do
          person.verification_types.each{|type| type.type_history_elements.delete_all }
          allow(subject).to receive(:find_person).with(individual_id).and_return(person)
          subject.call(nil, nil, nil, nil, payload)
          expect(history_elements_DC.first.action).to eq 'Local Hub Response'
        end

        it 'stores reference to EventResponse in verification history element' do
          person.verification_types.each{|type| type.type_history_elements.delete_all }
          allow(subject).to receive(:find_person).with(individual_id).and_return(person)
          subject.call(nil, nil, nil, nil, payload)
          expect(
            BSON::ObjectId.from_string(history_elements_DC.first.event_response_record_id)
          ).to eq consumer_role.local_residency_responses.first.id
        end
      end

      context 'ADDRESS_NOT_IN_AREA' do
        before do
          person.consumer_role.aasm_state = 'sci_verified'
          allow(subject).to receive(:xml_to_hash).with(xml).and_return(xml_hash)
          allow(subject).to receive(:find_person).with(individual_id).and_return(person)
          subject.call(nil, nil, nil, nil, payload)
          @consumer_role = person.consumer_role
        end

        if self_attest_residency_enabled?
          it 'should fully verify consumer role' do
            expect(@consumer_role.aasm_state).to eq('fully_verified')
          end

          it 'should attest dc residency type' do
            expect(person.verification_type_by_name('DC Residency').validation_status).to eq('attested')
          end

          it 'should store the ADDRESS_NOT_IN_AREA payload' do
            expect(@consumer_role.local_residency_responses.first.body).to include('ADDRESS_NOT_IN_AREA')
          end

          it 'should add reason to newly created workflow_state_transition' do
            expect(@consumer_role.workflow_state_transitions.last.reason).to eq('Self Attest DC Residency')
          end
        else
          it 'should update consumer role state to outstanding' do
            expect(@consumer_role.aasm_state).to eq('verification_outstanding')
          end

          it 'should store dc residency type status to outstanding' do
            expect(person.verification_type_by_name('DC Residency').validation_status).to eq('outstanding')
          end

          it 'should store the response payload' do
            expect(@consumer_role.local_residency_responses.count).to eq(1)
            expect(@consumer_role.local_residency_responses.first.body).to eq(payload[:body])
          end
        end
      end

      context 'ADDRESS_IN_AREA' do
        it 'should approve local residency' do
          person.consumer_role.aasm_state = 'sci_verified'
          allow(subject).to receive(:xml_to_hash).with(xml).and_return(xml_hash2)
          allow(subject).to receive(:find_person).with(individual_id).and_return(person)
          subject.call(nil, nil, nil, nil, payload)
          expect(person.consumer_role.aasm_state).to eq('fully_verified')
          expect(person.consumer_role.local_residency_responses.count).to eq(1)
          expect(person.consumer_role.local_residency_responses.first.body).to eq(payload[:body])
        end
      end
    end

    context 'response saving' do
      let(:consumer_role) { FactoryBot.create(:consumer_role_object) }
      let(:person_id) { consumer_role.person.id }
      let(:payload) { 'lsjdfioennnklsjdfe' }

      it 'should store responses correctly' do
        consumer_role.local_residency_responses << EventResponse.new({received_at: Time.zone.now, body: payload})
        consumer_role.person.save!
        found_person = Person.find(person_id)
        ssa_response = found_person.consumer_role.local_residency_responses.first
        expect(ssa_response.body).to eq payload
        consumer_role.local_residency_responses << EventResponse.new({received_at: Time.zone.now, body: payload})
        found_person = Person.find(person_id)
        expect(found_person.consumer_role.local_residency_responses.length).to eq(2)
      end
    end

  end
end
