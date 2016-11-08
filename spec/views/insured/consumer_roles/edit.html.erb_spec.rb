require "rails_helper"

RSpec.describe "insured/consumer_roles/edit.html.erb" do
  let(:person) { FactoryGirl.create(:person) }
  let(:consumer_role) { FactoryGirl.create(:consumer_role) }
  let(:current_user) {FactoryGirl.create(:user)}
  before :each do
    assign(:person, person)
    assign(:consumer_role, consumer_role)
    allow(consumer_role).to receive(:person).and_return person
    allow(person).to receive(:consumer_role).and_return consumer_role
    allow(consumer_role).to receive(:citizen_status)
    allow(consumer_role).to receive(:persisted?)
    allow(consumer_role ).to receive(:contact_method)
    allow(consumer_role ).to receive(:language_preference)
    allow(consumer_role).to receive(:vlp_document_id)
    allow(consumer_role).to receive(:find_document)
    sign_in current_user
    allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", updateable?: true))
    render file: "insured/consumer_roles/edit.html.erb"
  end

  it "should display the page info" do
    expect(rendered).to match(/#{person.first_name}/)
    expect(rendered).to match(/#{person.last_name}/)
    expect(rendered).to match(/#{person.dob}/)
    expect(rendered).to match(/#{person.ssn}/)
    expect(rendered).to match(/#{person.consumer_role.contact_method}/)
    expect(rendered).to match(/#{person.consumer_role.language_preference}/)
    expect(rendered).to match(/#{person.gender}/)
    expect(rendered).to match(/#{person.emails.last.address}/mi)
    expect(rendered).to match(/Please answer the following questions, provide your address/)
    #expect(rendered).to have_selector('h3', text: 'Enroll - let\'s get you signed up for healthcare')
    #expect(rendered).to have_selector('h5', text: 'Please indicate preferred method to receive notices (OPTIONAL)')
  end

  it "shouldn't display the docs fields" do
    expect(rendered).not_to match(/immigration_i_327_fields_container/)
    expect(rendered).not_to match(/immigration_i_766_fields_container/)
    expect(rendered).not_to match(/immigration_i_571_fields_container/)
    expect(rendered).not_to match(/immigration_i_94_fields_container/)
    expect(rendered).not_to match(/immigration_i_94_2_fields_container/)
    expect(rendered).not_to match(/machine_readable_immigrant_visa_fields_container/)
    expect(rendered).not_to match(/immigration_i_551_fields_container/)
    expect(rendered).not_to match(/immigration_temporary_i_551_stamp_fields_container/)
    expect(rendered).not_to match(/immigration_i_94_2_fields_container/)
    expect(rendered).not_to match(/immigration_other_with_i94_fields_container/)
    expect(rendered).not_to match(/immigration_other_with_alien_number_fields_container/)
    expect(rendered).not_to match(/immigration_i_766_fields_container/)
    expect(rendered).not_to match(/immigration_unexpired_foreign_passport_fields_container/)
  end

  it "should display the consumer_fields" do
    expect(rendered).to have_selector('#consumer_fields')
  end

  it "should display the naturalized_citizen_container" do
    expect(rendered).to have_selector('#naturalized_citizen_container')
  end

  it "should display the immigration_status_container" do
    expect(rendered).to have_selector("#immigration_status_container")
  end

  it "should display the indian_tribe_area" do
    expect(rendered).to have_selector("#indian_tribe_area")
  end

  it "should display the vlp document area" do
    expect(rendered).to have_selector('#vlp_documents_container')
    expect(rendered).to have_selector('#immigration_doc_type')
    expect(rendered).to have_selector('#naturalization_doc_type')
    expect(rendered).to have_selector('input#vlp_doc_target_id')
    expect(rendered).to have_selector('input#vlp_doc_target_type')
    expect(rendered).to have_selector('.vlp_doc_area')
  end

  it "shouldn't display the docs fields" do
    expect(rendered).not_to match(/immigration_i_327_fields_container/)
    expect(rendered).not_to match(/immigration_i_766_fields_container/)
    expect(rendered).not_to match(/immigration_i_571_fields_container/)
    expect(rendered).not_to match(/immigration_i_94_fields_container/)
    expect(rendered).not_to match(/immigration_i_94_2_fields_container/)
    expect(rendered).not_to match(/machine_readable_immigrant_visa_fields_container/)
    expect(rendered).not_to match(/immigration_i_551_fields_container/)
    expect(rendered).not_to match(/immigration_temporary_i_551_stamp_fields_container/)
    expect(rendered).not_to match(/immigration_i_94_2_fields_container/)
    expect(rendered).not_to match(/immigration_other_with_i94_fields_container/)
    expect(rendered).not_to match(/immigration_other_with_alien_number_fields_container/)
    expect(rendered).not_to match(/immigration_i_766_fields_container/)
    expect(rendered).not_to match(/immigration_unexpired_foreign_passport_fields_container/)
  end

  it "should display the consumer_fields" do
    expect(rendered).to have_selector('#consumer_fields')
  end

  it "should display the naturalized_citizen_container" do
    expect(rendered).to have_selector('#naturalized_citizen_container')
  end

  it "should display the immigration_status_container" do
    expect(rendered).to have_selector("#immigration_status_container")
  end

  it "should display the indian_tribe_area" do
    expect(rendered).to have_selector("#indian_tribe_area")
  end

  it "should display the vlp document area" do
    expect(rendered).to have_selector('#vlp_documents_container')
    expect(rendered).to have_selector('#immigration_doc_type')
    expect(rendered).to have_selector('#naturalization_doc_type')
    expect(rendered).to have_selector('input#vlp_doc_target_id')
    expect(rendered).to have_selector('input#vlp_doc_target_type')
    expect(rendered).to have_selector('.vlp_doc_area')
  end
end
