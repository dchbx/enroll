require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'fix_document_status_on_family')

describe FixDocumentStatus, dbclean: :after_each do
  subject { FixDocumentStatus.new('fix_document_status_on_family', double(:current_scope => nil)) }
  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
  let(:family_person) {family.primary_applicant.person}

  before(:each) do
    allow(ENV).to receive(:[]).with("hbx_ids").and_return "#{family_person.hbx_id}"
  end

  it "should update the document status on family" do
    family_person.consumer_role.is_state_resident = true
    family_person.consumer_role.update_attributes(ssn_validation: "valid")
    family_person.save!
    family.update_family_document_status!
    expect(family.all_persons_vlp_documents_status).to eq("Fully Uploaded")
    family_person.consumer_role.vlp_documents.first.destroy
    subject.migrate
    family.reload
    expect(family.vlp_documents_status).to eq("None")
  end
end