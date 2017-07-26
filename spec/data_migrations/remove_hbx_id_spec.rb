require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_hbx_id")

describe RemoveHbxId do
  let(:given_task_name) { "remove_hbx_id" }
  subject { RemoveHbxId.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing person ssn" do
    let(:person) { FactoryGirl.create(:person)}
    before(:each) do
      allow(ENV).to receive(:[]).with("person_hbx_id").and_return(person.hbx_id)
    end

    it "should set person hbx id to nil" do
      subject.migrate
      person.reload
      expect(person.hbx_id).to eq nil
    end
  end
end