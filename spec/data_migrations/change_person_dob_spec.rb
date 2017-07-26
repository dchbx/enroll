require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_person_dob")
describe ChangePersonDob, dbclean: :after_each do
  let(:given_task_name) { "change_person_dob" }
  subject { ChangePersonDob.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "changing person's date of birth" do
    let(:person) { FactoryGirl.create(:person)}
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(person.hbx_id)
      allow(ENV).to receive(:[]).with("new_dob").and_return("01/01/2011")
    end

    it "should change effective on date" do
      dob=person.dob
      expect(person.dob).to eq dob
      subject.migrate
      person.reload
      expect(person.dob).to eq Date.new(2011,1,1)
    end
  end
end
