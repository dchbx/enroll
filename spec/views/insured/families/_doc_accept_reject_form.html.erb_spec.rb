require 'rails_helper'

describe "insured/families/verification/_doc_accept_reject_form" do
  let(:person) { FactoryGirl.build(:person, :with_consumer_role) }
  let(:vlp_doc) { FactoryGirl.build(:vlp_document) }
  before :each do
    assign :person, person
    assign :vlp_doc, vlp_doc
  end
  context "consumer side" do
    before :each do
      allow(view).to receive_message_chain("current_user.has_hbx_staff_role?").and_return false
      render "insured/families/verification/doc_accept_reject_form.html.erb"
    end
    it "should NOT have accept and reject button" do
      expect(rendered).not_to match /accept/
      expect(rendered).not_to match /reject/
    end
  end
end