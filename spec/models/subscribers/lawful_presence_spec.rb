require "rails_helper"

describe Subscribers::LawfulPresence do

  it "should subscribe to the correct event" do
    expect(Subscribers::LawfulPresence.subscription_details).to eq ["acapi.info.events.lawful_presence.vlp_verification_response"]
  end

  it "should return the correct citizenship status" do
    expect(subject.send(:get_citizen_status, "citizen")).to eq("us_citizen")
    expect(subject.send(:get_citizen_status, "refugee")).to eq("alien_lawfully_present")
    expect(subject.send(:get_citizen_status, "student")).to eq("alien_lawfully_present")
    expect(subject.send(:get_citizen_status, "non_immigrant")).to eq("alien_lawfully_present")
    expect(subject.send(:get_citizen_status, "asylum_application_pending")).to eq("alien_lawfully_present")
    expect(subject.send(:get_citizen_status, "lawful_permanent_resident")).to eq("lawful_permanent_resident")
  end

  describe "given a ssa verification message to handle" do
    let(:individual_id) { "121211" }
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "lawful_presence_payloads", "response.xml")) }
    let(:xml2) { File.read(Rails.root.join("spec", "test_data", "lawful_presence_payloads", "response2.xml")) }
    let(:xml_hash) { {:case_number => "12121", :lawful_presence_determination => {
        :response_code => "lawfully_present", :legal_status => "lawful_permanent_resident"}} }
    let(:xml_hash2) { {:case_number => "12121", :lawful_presence_indeterminate => {:response_code => "invalid_information",
                                                                                   :response_text => "Complete information."}} }
    let(:xml_hash3) { {:case_number => "12121", :lawful_presence_determination => {
        :response_code => "not_lawfully_present", :legal_status => "other"}} }

    let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
    let(:consumer_role) { person.consumer_role }

    before do
      consumer_role.aasm_state = "dhs_pending"
      consumer_role.citizen_status = "alien_lawfully_present"
      person.save
    end

    context "stores DHS response in verification history" do
      let(:payload) { {:individual_id => individual_id, :body => xml} }
      it "stores verification history element" do
        consumer_role.verification_type_history_elements.delete_all
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)
        expect(consumer_role.verification_type_history_elements.count).to be > 0
      end

      it "stores verification history element for right verification type" do
        consumer_role.verification_type_history_elements.delete_all
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)
        expect(consumer_role.verification_type_history_elements.first.verification_type).to eq "Immigration status"
      end

      it "stores reference to EventResponse in verification history element" do
        consumer_role.verification_type_history_elements.delete_all
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)
        expect(BSON::ObjectId.from_string(consumer_role.verification_type_history_elements.first.event_response_record_id)).to eq consumer_role.lawful_presence_determination.vlp_responses.first.id
      end
    end

    context "lawful_presence_determination" do
      let(:payload) { {:individual_id => individual_id, :body => xml} }
      context "lawfully_present" do
        it "should approve lawful presence" do
          allow(subject).to receive(:xml_to_hash).with(xml).and_return(xml_hash)
          allow(subject).to receive(:find_person).with(individual_id).and_return(person)
          subject.call(nil, nil, nil, nil, payload)
          expect(person.consumer_role.aasm_state).to eq('fully_verified')
          expect(person.consumer_role.lawful_presence_determination.vlp_authority).to eq('dhs')
          expect(Person.find(person.id).consumer_role.lawful_presence_determination.vlp_responses.count).to eq(1)
          expect(Person.find(person.id).consumer_role.lawful_presence_determination.vlp_responses.first.body).to eq(payload[:body])
        end
      end

      context "unlawfully_present" do
        it "should approve lawful presence" do
          allow(subject).to receive(:xml_to_hash).with(xml).and_return(xml_hash3)
          allow(subject).to receive(:find_person).with(individual_id).and_return(person)
          subject.call(nil, nil, nil, nil, payload)
          expect(person.consumer_role.aasm_state).to eq('verification_outstanding')
          expect(person.consumer_role.lawful_presence_determination.vlp_authority).to eq('dhs')
          expect(Person.find(person.id).consumer_role.lawful_presence_determination.vlp_responses.count).to eq(1)
          expect(Person.find(person.id).consumer_role.lawful_presence_determination.vlp_responses.first.body).to eq(payload[:body])
        end
      end
    end

    context "lawful_presence_indeterminate" do
      let(:payload) { {:individual_id => individual_id, :body => xml2} }
      it "should deny lawful presence" do
        allow(subject).to receive(:xml_to_hash).with(xml2).and_return(xml_hash2)
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)
        expect(person.consumer_role.aasm_state).to eq('verification_outstanding')
        expect(person.consumer_role.lawful_presence_determination.vlp_authority).to eq('dhs')
        expect(Person.find(person.id).consumer_role.lawful_presence_determination.vlp_responses.count).to eq(1)
        expect(Person.find(person.id).consumer_role.lawful_presence_determination.vlp_responses.first.body).to eq(payload[:body])
      end
    end

  end
end
