require "rails_helper"
if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
require File.join(Rails.root, "app", "data_migrations", "update_verification_types")

describe "UpdateVerificationTypes data migration", dbclean: :after_each do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role)}
  subject { UpdateVerificationTypes.new("fix me task", double(:current_scope => nil)) }
  shared_examples_for "update residency type for verified people" do |consumer_state, old_validation, attr_to_check, result|
    before do
      person.consumer_role.aasm_state = consumer_state
      person.consumer_role.update_attributes(:is_state_resident => nil, :residency_determined_at => Time.now, :local_residency_validation => old_validation)
      subject.migrate
      person.reload
    end
    it "updates verification type" do
      expect(person.consumer_role.send(attr_to_check)).to eq result
    end
  end

  context "fully verified person" do
    it_behaves_like "update residency type for verified people", "fully_verified", nil, "is_state_resident", true
    it_behaves_like "update residency type for verified people", "fully_verified", nil, "local_residency_validation", "valid"
  end

  context "sci verified person" do
    it_behaves_like "update residency type for verified people", "sci_verified", nil, "is_state_resident", true
    it_behaves_like "update residency type for verified people", "sci_verified", nil, "local_residency_validation", "valid"
  end

  context "not fully verified person" do
    it_behaves_like "update residency type for verified people", "verification_outstanding", nil, "is_state_resident", nil
    it_behaves_like "update residency type for verified people", "verification_outstanding", nil, "local_residency_validation", nil
    it_behaves_like "update residency type for verified people", "dhs_pending", nil, "is_state_resident", nil
    it_behaves_like "update residency type for verified people", "dhs_pending", nil, "local_residency_validation", nil
    it_behaves_like "update residency type for verified people", "ssa_pending", nil, "is_state_resident", nil
    it_behaves_like "update residency type for verified people", "ssa_pending", nil, "local_residency_validation", nil
    it_behaves_like "update residency type for verified people", "unverified", nil, "is_state_resident", nil
    it_behaves_like "update residency type for verified people", "unverified", nil, "local_residency_validation", nil
  end
end
end
