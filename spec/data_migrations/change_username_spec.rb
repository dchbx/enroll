require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_username")

describe ChangeUsername, dbclean: :after_each do
  let(:given_task_name) { "change_username" }
  subject { ChangeUsername.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "change the username of a user" do
    let(:user) { FactoryGirl.create(:user) }
    before(:each) do
      allow(ENV).to receive(:[]).with("old_user_oimid").and_return(user.oim_id)
      allow(ENV).to receive(:[]).with("new_user_oimid").and_return("NewUsername")
    end
    it "should change the username of the user" do
      username=user.oim_id
      expect(user.oim_id).to eq username
      subject.migrate
      user.reload
      expect(user.oim_id).to eq "NewUsername"
    end
  end
  
  describe "not change the username if the user not found" do
    let(:user) { FactoryGirl.create(:user) }
    before(:each) do
      allow(ENV).to receive(:[]).with("old_user_oimid").and_return("")
      allow(ENV).to receive(:[]).with("new_user_oimid").and_return("NewUsername")
    end
    it "should not change the username of the user" do
      username=user.oim_id
      expect(user.oim_id).to eq username
      subject.migrate
      user.reload
      expect(user.oim_id).to eq username
    end
  end

  describe "if new user already present in Enroll System" do
    let(:user) { FactoryGirl.create(:user) }
    let(:new_user) { FactoryGirl.create(:user) }
    before(:each) do
      allow(ENV).to receive(:[]).with("old_user_oimid").and_return(user.oim_id)
      allow(ENV).to receive(:[]).with("new_user_oimid").and_return(new_user.oim_id)
    end
    it "should not change the new username of the user" do
      username=user.oim_id
      expect(user.oim_id).to eq username
      subject.migrate
      user.reload
      expect(user.oim_id).not_to eq new_user.oim_id
    end
  end
end
