require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "disable_person_account")

describe DisablePersonAccount do

  let(:given_task_name) { "disable_person_account" }
  subject { DisablePersonAccount.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "disable person account", dbclean: :after_each do
    let(:person){FactoryGirl.create(:person,:with_family)}
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(person.hbx_id)
    end
    it "should disable the person's primary family" do
      subject.migrate
      person.reload
      expect(person.primary_family.is_active).to eq false
    end
  end
end