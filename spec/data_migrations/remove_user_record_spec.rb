require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_user_record")

describe RemoveUserRecord, dbclean: :after_each do

  let(:given_task_name) { "remove_user_record" }
  subject { RemoveUserRecord.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "deleting user record" do
    let(:person) { FactoryGirl.create(:person)}
    let(:user) { FactoryGirl.create(:user, person: person) }
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return person.hbx_id
      allow(person).to receive(:user).and_return(user)
    end

    it "should remove user record" do
      subject.migrate
      person.reload
      expect(Person.where(hbx_id: person.hbx_id).first.user).to eq nil
    end
  end
end
