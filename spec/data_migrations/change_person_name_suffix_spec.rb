require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_person_name_suffix")

describe ChangePersonNameSuffix, dbclean: :after_each do
  let(:given_task_name) { "change_person_name_suffix" }
  subject { ChangePersonNameSuffix.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "changing person's name suffix" do
    let(:person) { FactoryGirl.create(:person, name_sfx: "Jr")}
    let(:csv_row) { CSV::Row.new(["HBX ID","Potential Correct Suffix"],[person.hbx_id,"Jr."]) }

    it "should change the person's name suffix" do
      suffix = person.name_sfx
      expect(person.name_sfx).to eq suffix
      subject.process_row(csv_row)
      person.reload
      expect(person.name_sfx).to eq "Jr."
    end
  end
end