require 'rails_helper'

describe EventResponse do
  let(:ssa_body) { "<ssa_verification_result xmlns=\"http://openhbx.org/api/terms/1.0\"
              xmlns:env=\"http://schemas.xmlsoap.org/soap/envelope/\"
              xmlns:ns1=\"http://openhbx.org/api/terms/1.0\"
              xmlns:wsa=\"http://www.w3.org/2005/08/addressing\">
              <ns6:individual xmlns:bpmn=\"http://schemas.oracle.com/bpm/xpath\"
              xmlns:ns6=\"http://openhbx.org/api/terms/1.0\">
              <ns6:id><ns6:id>568e7eeb8fsdffgc</ns6:id></ns6:id>
              <ns6:person><ns6:id><ns6:id>urn:openhbx:hbx:dc0:resources:v1:person:hbx_id#xdffgg</ns6:id></ns6:id>
              <ns6:person_name><ns6:person_surname>Tysonibaison</ns6:person_surname>
              <ns6:person_given_name>Ramsey</ns6:person_given_name></ns6:person_name>
              <ns6:addresses><ns6:address><ns6:type>urn:openhbx:terms:v1:address_type#home</ns6:type>
              <ns6:address_line_1>000 Zauglom St</ns6:address_line_1>
              <ns6:location_city_name>Uryupinsk</ns6:location_city_name>
              <ns6:location_state_code>DC</ns6:location_state_code>
              <ns6:postal_code>20000</ns6:postal_code></ns6:address></ns6:addresses>
              <ns6:emails>
                <ns6:email><ns6:type>urn:openhbx:terms:v1:email_type#work</ns6:type>
                  <ns6:email_address>mail@mail.com</ns6:email_address>
                </ns6:email>
              </ns6:emails>
              <ns6:phones>
                <ns6:phone>
                  <ns6:type>urn:openhbx:terms:v1:phone_type#home</ns6:type>
                    <ns6:full_phone_number>2022022029</ns6:full_phone_number>
                  <ns6:is_preferred>false</ns6:is_preferred>
                </ns6:phone>
              </ns6:phones>
              </ns6:person>
              <ns6:person_demographics>
              <ns6:ssn>989898989</ns6:ssn>
              <ns6:sex>urn:openhbx:terms:v1:gender#female</ns6:sex>
              <ns6:birth_date>19700311</ns6:birth_date>
              <ns6:created_at>2015-10-11T02:01:03Z</ns6:created_at>
              <ns6:modified_at>2016-06-03T14:48:39Z</ns6:modified_at>
              </ns6:person_demographics></ns6:individual>
              <ns1:response_code>HS000000</ns1:response_code>
              <ns1:response_text>Success</ns1:response_text>
              <ns1:ssn_verification_failed>true</ns1:ssn_verification_failed>
              </ssa_verification_result>" }

  let(:vlp_body) { "<lawful_presence xmlns=\"http://openhbx.org/api/terms/1.0\"
                 xmlns:env=\"http://schemas.xmlsoap.org/soap/envelope/\"
                 xmlns:wsa=\"http://www.w3.org/2005/08/addressing\">
                      <case_number></case_number>
                      <lawful_presence_indeterminate>
                        <response_code>urn:openhbx:terms:v1:lawful_presence:determination#invalid_information</response_code>
                        <response_text xmlns:def=\"http://www.w3.org/2001/XMLSchema\"
                                       xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
                                       xsi:type=\"def:string\">
                                         com.oracle.bpel.client.BPELFault: faultName: {{http://docs.oasis-open.org/wsbpel/2.0/process/executable}invalidVariables}\n
                                         messageType: {{http://schemas.oracle.com/bpel/extension}RuntimeFaultMessage}\n
                                         parts: {{\nsummary=&lt;summary&gt;Failed to validate bpel variable.\n
                                         Validation of variable Invoke_FedLawfulPresenceSvc_In failed.\n
                                         The reason was: Element not completed: 'Agency3InitVerifRequest'\n
                                         Please handle the exception in bpel.&lt;/summary&gt;}\n
                        </response_text>
                      </lawful_presence_indeterminate>
                    </lawful_presence>" }
  let(:ssa_response) { FactoryGirl.build(:event_response, :body => ssa_body )  }
  let(:vlp_response) { FactoryGirl.build(:event_response, :body => vlp_body) }
  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }

  describe "#vlp_resp_to_hash" do
    before do
      person.consumer_role.lawful_presence_determination.vlp_responses << vlp_response
    end

    it "converts vlp response to hash format" do
      expect(person.consumer_role.lawful_presence_determination.vlp_responses.first.vlp_resp_to_hash).to be_an_instance_of Hash
    end

    it "allows to get lawful presence status" do
      expect(person.consumer_role.lawful_presence_determination.vlp_responses.first.vlp_resp_to_hash[:lawful_presence_indeterminate]).to be_truthy
    end
  end

  describe "#parse dhs" do
    before do
      person.consumer_role.lawful_presence_determination.vlp_responses << vlp_response
    end

    it "returns array with results" do
      expect(person.consumer_role.lawful_presence_determination.vlp_responses.first.parse_dhs).to be_an_instance_of Array
    end

    it "parse the response to result for showing" do
      expect(person.consumer_role.lawful_presence_determination.vlp_responses.first.parse_dhs).to eq ["invalid information", "not lawfully present"]
    end
  end

  describe "#parse ssa" do
    before do
      person.consumer_role.lawful_presence_determination.ssa_responses << ssa_response
    end

    it "returns array with results" do
      expect(person.consumer_role.lawful_presence_determination.ssa_responses.first.parse_ssa).to be_an_instance_of Array
    end

    it "parse the response to result for showing" do
      expect(person.consumer_role.lawful_presence_determination.ssa_responses.first.parse_ssa).to eq [false, false]
    end
  end
end
