require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "fix_citizen_for_hub_responses")

ACCEPTABLE_STATES = %w(us_citizen naturalized_citizen alien_lawfully_present lawful_permanent_resident indian_tribe_member not_lawfully_present_in_us)
NOT_ACCEPTABLE_STATES = %w(undocumented_immigrant non_native_not_lawfully_present_in_us ssn_pass_citizenship_fails_with_SSA non_native_citizen)
STATES_TO_FIX = ["not_lawfully_present_in_us", "non_native_not_lawfully_present_in_us", "ssn_pass_citizenship_fails_with_SSA", nil]

describe UpdateCitizenStatus, dbclean: :after_each do
  subject { UpdateCitizenStatus.new("fix_citizen_for_hub_responses", double(:current_scope => nil)) }
  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
  let(:person1) { FactoryGirl.create(:person, :with_consumer_role) }
  let(:person2) { FactoryGirl.create(:person, :with_consumer_role) }

  shared_examples_for "fixing citizen status for consumer" do |old_state, new_state, result, vlp_authority|
    before do
      person1.consumer_role.lawful_presence_determination.update_attributes!(citizen_status: old_state, vlp_authority: vlp_authority)
      person2.consumer_role.lawful_presence_determination.update_attributes!(citizen_status: new_state, vlp_authority: vlp_authority)
      person.consumer_role.lawful_presence_determination.update_attributes!(citizen_status: new_state, vlp_authority: vlp_authority)
      allow(subject).to receive(:get_people).and_return([person])
      allow(person).to receive(:versions).and_return([person1, person2])
      subject.migrate
    end

    it "assigns #{result} as citizen status if old status: #{old_state} and current status: #{new_state}" do
      expect(person.consumer_role.lawful_presence_determination.citizen_status).to eq(result)
    end
  end

  context "citizen status wasn't changed" do
    it_behaves_like "fixing citizen status for consumer", "us_citizen", "us_citizen", "us_citizen", "ssa"
  end

  STATES_TO_FIX.each do |status|
    context "citizen state was valid but has been changed to #{status}" do
      it_behaves_like "fixing citizen status for consumer", "us_citizen", status, "us_citizen", nil
    end
    context "citizen state was not valid but has been changed to #{status}" do
      it_behaves_like "fixing citizen status for consumer", status, "us_citizen", "us_citizen", nil
    end
    context "citizen state was valid with ssa authority but has been changed to #{status}" do
      it_behaves_like "fixing citizen status for consumer", "us_citizen", status, status, "ssa"
    end
    context "citizen state was valid with dhs authority but has been changed to #{status}" do
      it_behaves_like "fixing citizen status for consumer", "us_citizen", status, status, "dhs"
    end
    context "citizen state was valid with curam authority but has been changed to #{status}" do
      it_behaves_like "fixing citizen status for consumer", "us_citizen", status, "us_citizen", "curam"
    end
  end
end
