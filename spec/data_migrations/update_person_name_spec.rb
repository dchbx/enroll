require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_person_name")
describe UpdatePersonName, dbclean: :after_each do
  let(:given_task_name) { "update_person_name" }
  subject { UpdatePersonName.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "changing person's name" do
    let(:person) { FactoryGirl.create(:person, first_name: 'James', last_name: 'federer')}
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(person.hbx_id)
      allow(ENV).to receive(:[]).with("first_name").and_return("Chirec")
      allow(ENV).to receive(:[]).with("last_name").and_return("Yuin")
    end

    it "should change name of the person" do
      subject.migrate
      person.reload
       expect(person.first_name).to eq 'Chirec'
       expect(person.last_name).to eq 'Yuin'
    end
  end
end
