require "rails_helper"
if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
require File.join(Rails.root, "app", "data_migrations", "fix_hub_verified_consumer")

describe FixHubVerifiedConsumer, :dbclean => :after_each do
  subject { FixHubVerifiedConsumer.new("fix_hub_verified_consumer", double(:current_scope => nil)) }
  let(:response_date) { Time.mktime(2016,7,5,8,0,0) }
  let(:body_ssn_true_citizenship_true) {"<ssa_verification_result xmlns=\"http://openhbx.org/api/terms/1.0\"
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
              <ns1:ssn_verified>true</ns1:ssn_verified>
              <ns1:citizenship_verified>true</ns1:citizenship_verified>
              <ns1:incarcerated>false</ns1:incarcerated>
              <ns1:response_text>Success</ns1:response_text>
              </ssa_verification_result>"}

  let(:body_ssn_true_citizenship_false) {
    doc = Nokogiri::XML(body_ssn_true_citizenship_true)
    doc.xpath("//ns1:citizenship_verified", {:ns1 => "http://openhbx.org/api/terms/1.0"}).first.content = "false"
    doc.to_xml(:indent => 2)
  }

  let(:body_ssn_true_NO_citizenship) {
    doc = Nokogiri::XML(body_ssn_true_citizenship_true)
    doc.xpath("//ns1:citizenship_verified", {:ns1 => "http://openhbx.org/api/terms/1.0"}).remove
    doc.to_xml(:indent => 2)
  }

  let(:body_no_ssn_verified_element) {
    "<ssa_verification_result xmlns=\"http://openhbx.org/api/terms/1.0\"
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
              </ssa_verification_result>"
  }

  let(:body_dhs_presense_false) { "<lawful_presence xmlns=\"http://openhbx.org/api/terms/1.0\"
                                  xmlns:env=\"http://schemas.xmlsoap.org/soap/envelope/\"
                                  xmlns:wsa=\"http://www.w3.org/2005/08/addressing\"><case_number></case_number>
                                    <lawful_presence_indeterminate>
                                      <response_code>
                                        urn:openhbx:terms:v1:lawful_presence:determination#invalid_information
                                      </response_code>
                                      <response_text xmlns:def=\"http://www.w3.org/2001/XMLSchema\"
                                        xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
                                        xsi:type=\"def:string\">com.oracle.bpel.client.BPELFault: faultName:
                                        {{http://docs.oasis-open.org/wsbpel/2.0/process/executable}invalidVariables}\nmessageType:
                                        {{http://schemas.oracle.com/bpel/extension}RuntimeFaultMessage}\nparts:
                                        {{\nsummary=&lt;summary&gt;Failed to validate bpel variable.\nValidation of variable Invoke_FedLawfulPresenceSvc_In failed.\n
                                        The reason was: Element not completed: 'Agency3InitVerifRequest'\n
                                        Please handle the exception in bpel.&lt;/summary&gt;}\n
                                      </response_text>
                                    </lawful_presence_indeterminate>
                                  </lawful_presence>"

  }

  let(:body_dhs_presense_true) { "<lawful_presence xmlns=\"http://openhbx.org/api/terms/1.0\"
                                  xmlns:env=\"http://schemas.xmlsoap.org/soap/envelope/\"
                                  xmlns:ns1=\"http://openhbx.org/api/terms/1.0\"
                                  xmlns:wsa=\"http://www.w3.org/2005/08/addressing\">
                                  <ns1:case_number>XXX</ns1:case_number>
                                    <ns1:lawful_presence_determination>
                                  <ns1:response_code>
                                    urn:openhbx:terms:v1:lawful_presence:determination#lawfully_present</ns1:response_code>
                                  <ns1:response_text>
                                    II000000-Success
                                  </ns1:response_text>
                                  <ns1:legal_status>
                                    urn:openhbx:terms:v1:lawful_presence:presence_status#citizen
                                  </ns1:legal_status>
                                  <ns1:employment_authorized>
                                    urn:openhbx:terms:v1:lawful_presence:employment_authorization#authorized
                                  </ns1:employment_authorized>
                                  <ns1:document_results>
                                    <ns1:document_cert_of_naturalization>
                                  <ns1:case_number>XXXX</ns1:case_number>
                                  <ns1:response_code>XXX000</ns1:response_code>
                                  <ns1:response_description_text>XXXX00000-Success</ns1:response_description_text>
                                  <ns1:tds_response_description_text>Success</ns1:tds_response_description_text>
                                  <ns1:country_birth_code>EGYPT</ns1:country_birth_code>
                                  <ns1:country_citizen_code>INDIA</ns1:country_citizen_code><ns1:coa_code>USC</ns1:coa_code>
                                  <ns1:elig_statement_code>24</ns1:elig_statement_code>
                                  <ns1:elig_statement_txt>UNITED STATES CITIZEN</ns1:elig_statement_txt>
                                  </ns1:document_cert_of_naturalization></ns1:document_results>
                                  </ns1:lawful_presence_determination>
                                  </lawful_presence>"

  }

  let(:ssa_response_ssn_true_citizenship_true) { EventResponse.new({:received_at => response_date, :body => body_ssn_true_citizenship_true}) }
  let(:ssa_response_ssn_true_citizenship_false) { EventResponse.new({:received_at => response_date, :body => body_ssn_true_citizenship_false}) }
  let(:ssa_response_ssn_true_NO_citizenship) { EventResponse.new({:received_at => response_date, :body => body_ssn_true_NO_citizenship}) }
  let(:ssa_response_ssn_false) { EventResponse.new({:received_at => response_date, :body => body_no_ssn_verified_element}) }
  let(:dhs_response_false) { EventResponse.new({:received_at => response_date, :body => body_dhs_presense_false}) }
  let(:dhs_response_true) { EventResponse.new({:received_at => response_date, :body => body_dhs_presense_true}) }
  let(:person) { FactoryGirl.create(:person, :with_consumer_role)}

  shared_examples_for "consumer verification status" do |action, old_status, new_status|
    it "#{action} #{old_status} in #{new_status}" do
      expect(person.consumer_role.aasm_state).to eq new_status
    end
  end

  shared_examples_for "consumer verification types" do |action, v_type, status|
    it "#{action} #{v_type} as #{status}" do
      if v_type == 'Social Security Number'
        expect(person.consumer_role.ssn_validation).to eq status
      elsif v_type == 'Citizenship' || v_type == 'Immigration status'
        expect(person.consumer_role.lawful_presence_determination.aasm_state).to eq status
      end
    end
  end

  shared_examples_for "person has correct verification types" do |v_types|
    it "returns correct verification types for person" do
      expect(person.verification_types).to eq v_types
    end
  end

  describe "consumer has verification_outstanding status" do
    before :each do
      person.consumer_role.aasm_state = "verification_outstanding"
      person.consumer_role.lawful_presence_determination.aasm_state = "verification_outstanding"
    end
    describe "SSN, Citizenship, SSA Hub response" do
      context "SSA response: SSN - ok, Citizenship - ok" do
        before :each do
          person.consumer_role.lawful_presence_determination.ssa_responses << ssa_response_ssn_true_citizenship_true
          person.save!
          subject.migrate
          person.reload
        end
        it_behaves_like "person has correct verification types", ["DC Residency", "Social Security Number", "Citizenship"]
        it_behaves_like "consumer verification types", "set", "Social Security Number", "valid"
        it_behaves_like "consumer verification types", "set", "Citizenship", "verification_successful"
        it_behaves_like "consumer verification status", "updates", "verification_outstanding", "fully_verified"
      end
      context "SSA response: SSN - ok, Citizenship - fail" do
        before :each do
          person.consumer_role.lawful_presence_determination.ssa_responses << ssa_response_ssn_true_citizenship_false
          person.save!
          subject.migrate
          person.reload
        end
        it_behaves_like "person has correct verification types", ["DC Residency", "Social Security Number", "Citizenship"]
        it_behaves_like "consumer verification types", "set", "Social Security Number", "valid"
        it_behaves_like "consumer verification status", "remains", "verification_outstanding", "verification_outstanding"
      end
      context "SSA response: SSN - fail" do
        before :each do
          person.consumer_role.lawful_presence_determination.ssa_responses << ssa_response_ssn_false
          person.save!
          subject.migrate
          person.reload
        end
        it_behaves_like "person has correct verification types", ["DC Residency", "Social Security Number", "Citizenship"]
        it_behaves_like "consumer verification types", "set", "Social Security Number", "pending"
        it_behaves_like "consumer verification status", "remains", "verification_outstanding", "verification_outstanding"
      end
    end
    describe "SSN, Citizenship, SSA and DHS Hub response" do
      context "SSA response: SSN - ok, Citizenship - false. DHS response: Immigration - false" do
        before :each do
          person.consumer_role.citizen_status = "alien_lawfully_present"
          person.consumer_role.lawful_presence_determination.ssa_responses << ssa_response_ssn_true_citizenship_false
          person.consumer_role.lawful_presence_determination.vlp_responses << dhs_response_false
          person.save!
          subject.migrate
          person.reload
        end
        it_behaves_like "person has correct verification types", ["DC Residency", "Social Security Number", "Immigration status"]
        it_behaves_like "consumer verification types", "set", "Social Security Number", "valid"
        it_behaves_like "consumer verification types", "set", "Immigration status", "verification_outstanding"
        it_behaves_like "consumer verification status", "remains", "verification_outstanding", "verification_outstanding"
      end

      context "SSA response: SSN - ok, Citizenship - false. DHS response: Immigration - ok" do
        before :each do
          person.consumer_role.citizen_status = "alien_lawfully_present"
          person.consumer_role.lawful_presence_determination.ssa_responses << ssa_response_ssn_true_citizenship_false
          person.consumer_role.lawful_presence_determination.vlp_responses << dhs_response_true
          person.save!
          subject.migrate
          person.reload
        end
        it_behaves_like "person has correct verification types", ["DC Residency", "Social Security Number", "Immigration status"]
        it_behaves_like "consumer verification types", "set", "Social Security Number", "valid"
        it_behaves_like "consumer verification types", "set", "Immigration status", "verification_successful"
        it_behaves_like "consumer verification status", "updates", "verification_outstanding", "fully_verified"
      end
    end
  end
end
end
