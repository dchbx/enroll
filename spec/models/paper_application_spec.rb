require 'rails_helper'

RSpec.describe PaperApplication, :type => :model do
  let(:person) {FactoryGirl.create(:person, :with_resident_role)}
  let(:person2) {FactoryGirl.create(:person, :with_resident_role)}


  describe "creates person with coverall paper application" do
    it "creates scope for uploaded application" do
      expect(person.resident_role.paper_applications).to exist
    end

    it "returns number of uploaded documents" do
      person2.resident_role.paper_applications.first.identifier = "url"
      expect(person2.resident_role.paper_applications.uploaded.count).to eq(1)
    end
  end

end
