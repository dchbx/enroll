require 'rails_helper'

RSpec.describe "insured/families/_navigate_to_curam_for_documents.html.erb" do

  context 'Person with consumer_role' do
    let(:person) {FactoryGirl.create(:person)}

    before :each do
      render partial: 'insured/families/navigate_to_curam_for_documents', locals: {display_text: "If you qualify for Medicaid, view your Medicaid documents." }
    end

    it "should have text" do
      expect(rendered).to have_content("Go to Medicaid")
    end

    it "should have a link" do
      expect(rendered).to have_link('Go to Medicaid')
    end

    it "should have text for documents" do
      expect(rendered).to have_content("If you qualify for Medicaid, view your Medicaid documents.")
    end
  end
end
