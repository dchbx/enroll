require "rails_helper"

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
describe Subscribers::SsaVerification do

  it "should subscribe to the correct event" do
    expect(Subscribers::SsaVerification.subscription_details).to eq ["acapi.info.events.lawful_presence.ssa_verification_response"]
  end

  describe "given a ssa verification message to handle" do
    let(:individual_id) { "121211" }
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "ssa_verification_payloads", "response.xml")) }
    let(:xml_hash) { {:response_code => "ss", :response_text => "Failed", :ssn_verification_failed => nil,
                      :death_confirmation => nil, :ssn_verified => "true", :citizenship_verified => "true",
                      :incarcerated => "false"} }
    let(:xml_hash2) { {:response_code => "ss", :response_text => "Failed", :ssn_verification_failed => "true" } }
    let(:xml_hash3) { {:response_code => "ss", :response_text => "Failed", :ssn_verification_failed => nil,
                      :death_confirmation => nil, :ssn_verified => "true", :citizenship_verified => "false",
                      :incarcerated => "false"} }
    let(:person) { FactoryGirl.create(:person, :with_consumer_role)}
    let(:consumer_role) { person.consumer_role }

    let(:payload) { {:individual_id => individual_id, :body => xml} }

    before :each do
      consumer_role.aasm_state="ssa_pending"
    end

    context "stores SSA response in verification history" do
      it "stores verification history element" do
        consumer_role.verification_type_history_elements.delete_all
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)
        expect(consumer_role.verification_type_history_elements.count).to be > 1
      end

      it "stores verification history element for right verification type" do
        consumer_role.verification_type_history_elements.delete_all
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)
        expect(consumer_role.verification_type_history_elements.map(&:verification_type)).to eq ["Social Security Number", "Citizenship"]
      end

      it "stores reference to EventResponse in verification history element" do
        consumer_role.verification_type_history_elements.delete_all
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)
        expect(BSON::ObjectId.from_string(consumer_role.verification_type_history_elements.first.event_response_record_id)).to eq consumer_role.lawful_presence_determination.ssa_responses.first.id
      end
      it "stores duplicate SSA records for both SSN and Citizenship types" do
        consumer_role.verification_type_history_elements.delete_all
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)
        expect(consumer_role.verification_type_history_elements.count).to eq 2
        expect(consumer_role.verification_type_history_elements[0].event_response_record_id).to eq consumer_role.verification_type_history_elements[1].event_response_record_id
      end
    end

    context "ssn_verified and citizenship_verified=true" do
      it "should approve lawful presence" do
        allow(subject).to receive(:xml_to_hash).with(xml).and_return(xml_hash)
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)
        expect(consumer_role.aasm_state).to eq('fully_verified')
        expect(consumer_role.lawful_presence_determination.vlp_authority).to eq('ssa')
        expect(consumer_role.lawful_presence_determination.citizen_status).to eq(::ConsumerRole::US_CITIZEN_STATUS)
        expect(consumer_role.lawful_presence_determination.ssa_responses.count).to eq(1)
        expect(consumer_role.lawful_presence_determination.ssa_responses.first.body).to eq(payload[:body])
      end
    end

    context "ssn_verified and citizenship_verified=false" do
      it "should approve lawful presence and set citizen_status to not_lawfully_present_in_us" do
        allow(subject).to receive(:xml_to_hash).with(xml).and_return(xml_hash3)
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)
        expect(consumer_role.aasm_state).to eq('verification_outstanding')
        expect(consumer_role.lawful_presence_determination.vlp_authority).to eq('ssa')
        #response doesn't change user's input
        expect(consumer_role.lawful_presence_determination.citizen_status).to eq(::ConsumerRole::US_CITIZEN_STATUS)
      end
    end

    context "ssn_verification_failed" do
      it "should deny lawful presence" do
        allow(subject).to receive(:xml_to_hash).with(xml).and_return(xml_hash2)
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)
        expect(consumer_role.aasm_state).to eq('verification_outstanding')
        expect(consumer_role.lawful_presence_determination.vlp_authority).to eq('ssa')
        expect(consumer_role.lawful_presence_determination.ssa_responses.count).to eq(1)
        #response doesn't change user's input
        expect(consumer_role.lawful_presence_determination.citizen_status).to eq(::ConsumerRole::US_CITIZEN_STATUS)
        expect(consumer_role.lawful_presence_determination.ssa_responses.first.body).to eq(payload[:body])
      end
    end

  end
end
end
