require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "add_role_to_user_account")
describe AddRoleToUserAccount, dbclean: :after_each do
  let(:given_task_name) { "add_role_to_user_account" }
  subject { AddRoleToUserAccount.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "add the role to  a user" do
    let(:user) { FactoryGirl.create(:user) }
    before(:each) do
      allow(ENV).to receive(:[]).with("user_id").and_return(user.id)
      allow(ENV).to receive(:[]).with("new_role").and_return("consumer")
    end
    it "should add the role" do
      size = user.roles.size
      subject.migrate
      user.reload
      expect(user.roles.size).to eq size+1
    end
  end
  describe "add the role to  a user" do
    let(:user) { FactoryGirl.create(:user) }
    before(:each) do
      allow(ENV).to receive(:[]).with("user_id").and_return(user.id)
      allow(ENV).to receive(:[]).with("new_role").and_return("consumer")
    end
    it "should add the specific role to user" do
      expect(user.roles).not_to include("consumer")
      subject.migrate
      user.reload
      expect(user.roles).to include("consumer")
    end
  end
end
