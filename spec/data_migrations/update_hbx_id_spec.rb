require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_hbx_id")

describe UpdateHbxId do
  let(:given_task_name) { "update_hbx_id" }
  subject { UpdateHbxId.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing hbx id within person records" do
    let(:person1) { FactoryGirl.create(:person)}
    let(:person2) { FactoryGirl.create(:person)}
    let(:correct_hbxid) {person1.hbx_id}
    let(:incorrect_hbxid) {person2.hbx_id}

    before(:each) do
      allow(ENV).to receive(:[]).with("valid_hbxid").and_return(correct_hbxid)
      allow(ENV).to receive(:[]).with("invalid_hbxid").and_return(incorrect_hbxid)
    end

    it "should exchange hbx id " do
      subject.migrate
      person2.reload
      expect(person2.hbx_id).to eq correct_hbxid
    end

    it "should unset hbx id " do
      subject.migrate
      person1.reload
      expect(person1.hbx_id).to eq nil
    end

    it "should not exchange hbx id if any hbx_id is nil" do
      allow(ENV).to receive(:[]).with("valid_hbxid").and_return('')
      subject.migrate
      person1.reload
      person2.reload
      expect(person1.hbx_id).to eq correct_hbxid
      expect(person2.hbx_id).to eq incorrect_hbxid
    end
  end
end
