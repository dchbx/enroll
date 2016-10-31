Given(/^Family with unverified family members and enrollment$/) do
  person = FactoryGirl.create(:person, :with_consumer_role)
  family = FactoryGirl.create(:family, :with_primary_family_member, person: person)
  enrollment = FactoryGirl.create(:hbx_enrollment,
                       household: family.active_household,
                       kind: "individual",
                       submitted_at: TimeKeeper.datetime_of_record - 3.day,
                       created_at: TimeKeeper.datetime_of_record - 3.day,
                       aasm_state: "enrolled_contingent")
end

Given(/^Every family member has SSA and DHS response$/) do
  family=Family.where("households.hbx_enrollments"=>{"$exists" =>true}).first
  person = family.family_members.first.person if family.enrollments.verification_needed.any?
  ssa_body_response = "<ssa_verification_result xmlns=\"http://openhbx.org/api/terms/1.0\"
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
              </ssa_verification_result>"

  dhs_body_response = "<lawful_presence xmlns=\"http://openhbx.org/api/terms/1.0\"
                        xmlns:env=\"http://schemas.xmlsoap.org/soap/envelope/\"
                        xmlns:wsa=\"http://www.w3.org/2005/08/addressing\">
                        <case_number></case_number>
                          <lawful_presence_indeterminate>
                            <response_code>
                              urn:openhbx:terms:v1:lawful_presence:determination#invalid_information
                            </response_code>
                            <response_text xmlns:def=\"http://www.w3.org/2001/XMLSchema\"
                              xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
                              xsi:type=\"def:string\">
                              com.oracle.bpel.client.BPELFault:
                              faultName: {{http://docs.oasis-open.org/wsbpel/2.0/process/executable}invalidVariables}\n
                              messageType: {{http://schemas.oracle.com/bpel/extension}RuntimeFaultMessage}\n
                              parts: {{\nsummary=&lt;summary&gt;Failed to validate bpel variable.\n
                              Validation of variable Invoke_FedLawfulPresenceSvc_In failed.\n
                              The reason was: Element not completed: 'Agency3InitVerifRequest'\n
                              Please handle the exception in bpel.&lt;/summary&gt;}\n
                            </response_text>
                          </lawful_presence_indeterminate>
                        </lawful_presence>"

  ssa_response = FactoryGirl.build(:event_response, :received_at => Date.new(2016,5,5), :body => ssa_body_response)
  dhs_response = FactoryGirl.build(:event_response, :received_at => Date.new(2016,6,6), :body => dhs_body_response)
  person.consumer_role.lawful_presence_determination.ssa_responses<<ssa_response
  person.consumer_role.lawful_presence_determination.vlp_responses<<dhs_response
end

Then(/^Admin schould see list of primary applicants with unverified family$/) do
  expect(page).to have_content('HBX ID')
  expect(page).to have_content('First name')
  expect(page).to have_content('Last name')
  expect(page).to have_content('Review')
end

When(/^Hbx Admin clicks on the Review button$/) do
  click_link "Review"
end

Then(/^Admin goes to Documents page for this consumer account$/) do
  expect(page).to have_content('Verification')
  expect(page).to have_content('FedHub')
  expect(page).to have_content('Verification Type')
  expect(page).to have_content('Status')
end

When(/^Admin click on FedHub tab$/) do
  click_link "FedHub"
end

Then(/^Admin should see table with Hub response details$/) do
  expect(page).to have_content('Family Member')
  expect(page).to have_content('SSA Response')
  expect(page).to have_content('DHS Response')
  expect(page).to have_content('Retriger Hub')
  expect(page).to have_content('Hub calls:')
end

Then(/^Parsed response from SSA hub$/) do
  expect(page).to have_content('SSA Received: 05/05/2016')
  expect(page).to have_content('SSN: verified')
  expect(page).to have_content('Citizenship: verified')
end

Then(/^Parsed response from DHS hub$/) do
  expect(page).to have_content('DHS Received: 06/06/2016')
  expect(page).to have_content('Response: invalid information')
  expect(page).to have_content('Legal status: not lawfully present')
end
