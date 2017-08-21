require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_last_portal_visited")
describe ChangeLastPortalVisited, dbclean: :after_each do
  let(:given_task_name) { "change_last_portal_visited" }
  subject { ChangeLastPortalVisited.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "change the last portal visited for a user" do
    let(:user) { FactoryGirl.create(:user) }
    before(:each) do
      allow(ENV).to receive(:[]).with("user_oimid").and_return(user.oim_id)
      allow(ENV).to receive(:[]).with("new_url").and_return("/insured/families/search")
    end
    it "should change the last visited url of the user" do
      last_portal_visited=user.last_portal_visited
      expect(user.last_portal_visited).to eq last_portal_visited
      subject.migrate
      user.reload
      expect(user.last_portal_visited).to eq "/insured/families/search"
    end
  end
  describe "not change the last visited url if the user not found" do
    let(:user) { FactoryGirl.create(:user) }
    before(:each) do
      allow(ENV).to receive(:[]).with("user_oimid").and_return("")
      allow(ENV).to receive(:[]).with("new_url").and_return("newemail@gmail.com")
    end
    it "should change the email of the user" do
      last_portal_visited=user.last_portal_visited
      expect(user.last_portal_visited).to eq last_portal_visited
      subject.migrate
      user.reload
      expect(user.last_portal_visited).to eq last_portal_visited
    end
  end
end
