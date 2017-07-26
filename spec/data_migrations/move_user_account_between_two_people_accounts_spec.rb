require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "move_user_account_between_two_people_accounts")
describe MoveUserAccountBetweenTwoPeopleAccounts do
  let(:given_task_name) { "move_user_account_between_two_people_accounts" }
  subject { MoveUserAccountBetweenTwoPeopleAccounts.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "move the user from person1 to person2 " do
    let(:person1) { FactoryGirl.create(:person,user:user)}
    let(:user){FactoryGirl.create(:user)}
    let(:person2){FactoryGirl.create(:person)}
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id_1").and_return(person1.hbx_id)
      allow(ENV).to receive(:[]).with("hbx_id_2").and_return(person2.hbx_id)
    end
    it "should move user from person1 to person2" do
      expect(person1.user).not_to eq nil
      expect(person2.user).to eq nil
      subject.migrate
      person1.reload
      person2.reload
      expect(person1.user).to eq nil
      expect(person2.user).not_to eq nil
    end
  end
  describe "not move the user if person not found " do
    let(:person1) { FactoryGirl.create(:person,user:user)}
    let(:user){FactoryGirl.create(:user)}
    let(:person2){FactoryGirl.create(:person)}
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id_1").and_return("")
      allow(ENV).to receive(:[]).with("hbx_id_2").and_return(person2.hbx_id)
    end
    it "should not move user from person1 to person2" do
      expect(person1.user).not_to eq nil
      expect(person2.user).to eq nil
      subject.migrate
      person1.reload
      person2.reload
      expect(person1.user).not_to eq nil
      expect(person2.user).to eq nil
    end
  end
  describe "not move the user if person1 has no user " do
    let(:person1) { FactoryGirl.create(:person)}
    let(:person2){FactoryGirl.create(:person)}
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id_1").and_return(person1.hbx_id)
      allow(ENV).to receive(:[]).with("hbx_id_2").and_return(person2.hbx_id)
    end
    it "should not move user from person1 to person2" do
      subject.migrate
      person1.reload
      person2.reload
      expect(person2.user).to eq nil
    end
  end
end
