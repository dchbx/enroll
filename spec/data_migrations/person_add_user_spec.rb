require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "person_add_user")

describe PersonAddUser do

  let(:given_task_name) { "person_add_user" }
  subject { PersonAddUser.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "add user to person", dbclean: :after_each do

    let(:person) { FactoryGirl.create(:person, user_id: "")}
    let(:user) { FactoryGirl.create(:user)}
    
    before(:each) do
      allow(ENV).to receive(:[]).with('email').and_return(user.email)
      allow(ENV).to receive(:[]).with('hbx_id').and_return(person.hbx_id)
    end

    context "adds user_id to person" do
      it "person should have user id" do
        expect(person.user_id).to eq nil
        subject.migrate
        person.reload
        expect(person.user_id).to eq user.id
      end
    end
  end
end
