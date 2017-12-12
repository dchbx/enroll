require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "add_primary_family_to_person")
describe AddPrimaryFamilyToPerson, dbclean: :after_each do
  let(:given_task_name) { "add_primary_family_to_person" }
  subject { AddPrimaryFamilyToPerson.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "add_primary_family_to_person", dbclean: :after_each do

    let(:person) { FactoryGirl.create(:person) }
    before do
      allow(ENV).to receive(:[]).with('hbx_id').and_return person.hbx_id
    end

    it "should add a primary family to the person" do
      expect(person.primary_family).to be_nil
      subject.migrate
      expect(person.primary_family).not_to be_nil
    end
  end

end