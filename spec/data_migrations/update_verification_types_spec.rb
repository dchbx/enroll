require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_verification_types")

describe "UpdateVerificationTypes data migration" do
  let(:verification_attr) { OpenStruct.new({ :determined_at => Time.now, :vlp_authority => "hbx" })}
  let(:person) { FactoryGirl.create(:person, :with_consumer_role)}
  subject { UpdateVerificationTypes.new("fix me task", double(:current_scope => nil)) }
  shared_examples_for "update verification types for fully verified people" do |result, old_authority, new_authority|
    before do
      result == true ? person.consumer_role.aasm_state = "fully_verified" : person.consumer_role.aasm_state = "outstanding"
      person.consumer_role.ssn_validation = "invalid"
      person.save(:validate => false)
      person.consumer_role.lawful_presence_determination.deny!(verification_attr)
      person.consumer_role.lawful_presence_determination.update_attributes(:vlp_authority => old_authority)
      subject.migrate
      person.reload
    end
    it "verification types updated? #{result == true}" do
      expect(person.consumer_role.all_types_verified?).to eq result
    end
    it "doesn't overwite existing curam vlp_authority" do
      expect(person.consumer_role.lawful_presence_determination.vlp_authority).to eq new_authority
    end
  end

  context "fully verified person" do
    it_behaves_like "update verification types for fully verified people", true, "hbx", "hbx"
    it_behaves_like "update verification types for fully verified people", true, "curam", "curam"
    it_behaves_like "update verification types for fully verified people", true, "any", "hbx"
  end

  context "not fully verified person" do
    it_behaves_like "update verification types for fully verified people", false, "hbx", "hbx"
    it_behaves_like "update verification types for fully verified people", false, "curam", "curam"
    it_behaves_like "update verification types for fully verified people", false, "any", "any"
  end
end

