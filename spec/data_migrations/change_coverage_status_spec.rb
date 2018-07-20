require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_coverage_status")

describe ChangeCoverageStatus, dbclean: :after_each do

  let(:given_task_name) { "move_enrollment_between_two_accounts" }
  subject { ChangeCoverageStatus.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "it should change coverage statuses" do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
    let(:person) { family.family_members[0].person }
    let!(:consumer_role) { FactoryGirl.create(:consumer_role, person: person) }
    before do
      allow(ENV).to receive(:[]).with('person_hbx_id').and_return person.hbx_id
      allow(ENV).to receive(:[]).with('status').and_return false
    end
    it "should change status to false" do
      expect(person.consumer_role.is_applying_coverage).to eq true
      subject.migrate
      person.consumer_role.reload
      expect(person.consumer_role.is_applying_coverage).to eq false
    end

  end
end