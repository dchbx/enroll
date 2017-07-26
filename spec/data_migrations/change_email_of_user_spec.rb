require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_email_of_user")
describe ChangeEmailOfUser, dbclean: :after_each do
  let(:given_task_name) { "change_email_of_user" }
  subject { ChangeEmailOfUser.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "change the email of a user" do
    let(:user) { FactoryGirl.create(:user) }
    before(:each) do
      allow(ENV).to receive(:[]).with("user_oimid").and_return(user.oim_id)
      allow(ENV).to receive(:[]).with("new_email").and_return("newemail@gmail.com")
    end
    it "should change the email of the user" do
      email=user.email
      expect(user.email).to eq email
      subject.migrate
      user.reload
      expect(user.email).to eq "newemail@gmail.com"
    end
  end
  describe "not change the email if the user not found" do
    let(:user) { FactoryGirl.create(:user) }
    before(:each) do
      allow(ENV).to receive(:[]).with("user_oimid").and_return("")
      allow(ENV).to receive(:[]).with("new_email").and_return("newemail@gmail.com")
    end
    it "should change the email of the user" do
      email=user.email
      expect(user.email).to eq email
      subject.migrate
      user.reload
      expect(user.email).to eq email
    end
  end
end
