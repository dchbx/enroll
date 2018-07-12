require "rails_helper"
if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
require File.join(Rails.root, "app", "data_migrations", "move_due_date_to_verification_type_level")

describe MoveDueDateToVerificationTypeLevel do

  let(:given_task_name) { "move_due_date_to_verification_type_level" }
  subject { MoveDueDateToVerificationTypeLevel.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "move due date to v_type level" do
    let!(:person) { FactoryGirl.create(:person, :with_family, :with_consumer_role)}
    let!(:enrollment) { FactoryGirl.create(:hbx_enrollment, 
      household: person.primary_family.active_household, 
      special_verification_period: TimeKeeper.date_of_record - 5.days,
      aasm_state: "enrolled_contingent"
    )}

    let!(:enrollment2) { FactoryGirl.create(:hbx_enrollment,
      household: person.primary_family.active_household,
      special_verification_period: nil,
      aasm_state: "shopping"
    )}

    before do
      allow(subject).to receive(:enrolled_policy).and_return enrollment
    end

    it "should not have any special verification records" do
      expect(person.consumer_role.special_verifications.size).to eq 0
    end

    it "should not create a special verification unless special_verification_period present on enrollment" do
      enrollment.update_attributes(special_verification_period: nil)
      invoke!
      expect(person.consumer_role.special_verifications.size).to eq 0
    end

    it "should create a new special verification record under consumer role" do
      invoke!
      expect(person.consumer_role.special_verifications.size).not_to eq 0
      expect(person.consumer_role.special_verifications.size).to eq person.verification_types.size
    end

    it "should not create a new special verification if already present" do
      invoke!
      sv_size = person.consumer_role.special_verifications.size
      invoke!
      expect(person.consumer_role.special_verifications.size).to eq sv_size
    end

    it "should not create any special verification if there is no enrolled enrolled_policy" do
      allow(subject).to receive(:enrolled_policy).and_return nil
      invoke!
      expect(person.consumer_role.special_verifications.size).to eq 0
    end

    def invoke!
      subject.migrate
      person.reload
    end
  end
end
end
