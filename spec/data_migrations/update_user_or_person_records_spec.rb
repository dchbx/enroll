require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_user_or_person_records")

describe UpdateUserOrPersonRecords do
  
  let(:given_task_name) { "update_user_or_person_records" }
  subject { UpdateUserOrPersonRecords.new(given_task_name, double(:current_scope => nil)) }
  
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update username & email on user and also destroying headless user", dbclean: :after_each do
    
    let(:user) { FactoryGirl.create(:user, :with_family)}    
    before do
      allow(ENV).to receive(:[]).with('action').and_return ""
      allow(ENV).to receive(:[]).with('user_email').and_return user.email
      allow(ENV).to receive(:[]).with('user_name').and_return user.oim_id
      allow(ENV).to receive(:[]).with('headless_user').and_return ""
      allow(ENV).to receive(:[]).with('find_user_by').and_return "email"
      allow(ENV).to receive(:[]).with('hbx_id').and_return nil
    end
    
    it "should update the username on the user" do
      allow(ENV).to receive(:[]).with('action').and_return "update_UserName"
      allow(ENV).to receive(:[]).with('user_name').and_return "UpdatE@This"
      subject.migrate
      user.reload
      expect(user.oim_id).to eq "UpdatE@This"
    end

    it "should update the email on the user" do
      allow(ENV).to receive(:[]).with('find_user_by').and_return "user_name"
      allow(ENV).to receive(:[]).with('user_email').and_return "updatingemail@gmail.com"
      allow(ENV).to receive(:[]).with('action').and_return "update_Email"
      subject.migrate
      user.reload
      expect(user.email).to eq "updatingemail@gmail.com"
    end

    it "should not destroy user record if it's not headless" do
      allow(ENV).to receive(:[]).with('find_user_by').and_return "user_name"
      allow(ENV).to receive(:[]).with('headless_user').and_return "yes"
      subject.migrate
      expect(User.where(email: user.email).present?).to eq true
    end

    it "should destroy the headless user" do
      allow(ENV).to receive(:[]).with('find_user_by').and_return "user_name"
      allow(ENV).to receive(:[]).with('headless_user').and_return "yes"
      user.person.destroy!
      subject.migrate
      expect(User.where(email: user.email).present?).to eq false
    end

    context "updating email on person record" do
      let(:person) { FactoryGirl.create(:person)}

      before do
        allow(ENV).to receive(:[]).with('action').and_return "update_person_home_email"
        allow(ENV).to receive(:[]).with('find_user_by').and_return nil
        allow(ENV).to receive(:[]).with('user_email').and_return nil
        allow(ENV).to receive(:[]).with('person_email').and_return "my_home1198@test.com"
        allow(ENV).to receive(:[]).with('hbx_id').and_return person.hbx_id
      end

      it "should update the home email on person record" do
        subject.migrate
        person.reload
        home_email = person.emails.detect { |email| email.kind == "home"}
        expect(home_email.address).to eq "my_home1198@test.com"
      end

      it "should update the work email on person record" do
        allow(ENV).to receive(:[]).with('action').and_return "update_person_work_email"
        allow(ENV).to receive(:[]).with('person_email').and_return "my_work1198@test.com"
        person.emails.first.update_attributes(kind: "work")
        subject.migrate
        person.reload
        home_email = person.emails.detect { |email| email.kind == "work"}
        expect(home_email.address).to eq "my_work1198@test.com"
      end
    end
  end
end