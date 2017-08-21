require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_incorrect_person_relationship")

describe RemoveIncorrectPersonRelationship, dbclean: :after_each do

  let(:given_task_name) { "remove_incorrect_person_relationship" }
  subject { RemoveIncorrectPersonRelationship.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "destroying person relationships" do

    let(:person) { FactoryGirl.create(:person)}

    before(:each) do
      person.person_relationships << PersonRelationship.new(kind: "child", relative_id: person.id)
      person.save!
      allow(ENV).to receive(:[]).with("hbx_id").and_return(person.hbx_id)
      allow(ENV).to receive(:[]).with("_id").and_return(person.person_relationships.first.id)
    end

    it "should destroy the person relationship" do
      subject.migrate
      person.reload
      expect(person.person_relationships.size).to eq 0
    end
  end
end
