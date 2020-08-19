require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_user_or_person_records")

describe UpdateUserOrPersonRecords, dbclean: :after_each do

  let(:given_task_name) { "update_user_or_person_records" }
  let(:user) { FactoryGirl.create(:user, :with_family)}
  subject { UpdateUserOrPersonRecords.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  before do
    allow(ENV).to receive(:[]).with('action').and_return ""
    allow(ENV).to receive(:[]).with('user_email').and_return user.email
    allow(ENV).to receive(:[]).with('user_name').and_return user.oim_id
    allow(ENV).to receive(:[]).with('headless_user').and_return ""
    allow(ENV).to receive(:[]).with('find_user_by').and_return "email"
    allow(ENV).to receive(:[]).with('hbx_id').and_return nil
    allow(ENV).to receive(:[]).with('new_user_email').and_return nil
    allow(ENV).to receive(:[]).with('new_user_name').and_return nil
    allow(ENV).to receive(:[]).with('dob').and_return nil
  end

  describe "update username & email on user and also destroying headless user", dbclean: :after_each do

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
  end

  describe "updating or creating person info" do
    let(:person) { FactoryGirl.create(:person)}

    before do
      allow(ENV).to receive(:[]).with('action').and_return "update_person_home_email"
      allow(ENV).to receive(:[]).with('find_user_by').and_return nil
      allow(ENV).to receive(:[]).with('user_email').and_return nil
      allow(ENV).to receive(:[]).with('person_email').and_return "my_home1198@test.com"
      allow(ENV).to receive(:[]).with('hbx_id').and_return person.hbx_id
    end

    context "updating email on person record" do

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

    context "create email record on person" do

      context "if you say 'yes' to create a new email" do

        before do
          allow(STDIN).to receive(:gets).and_return "yes"
        end

        it "should create a new home email" do
          person.emails.delete_if { |email| email.kind == "home"}
          subject.migrate
          person.reload
          expect(person.emails.select { |email| email.kind == "home"}.size).to eq 1
        end

        it "should create a new work email" do
          allow(ENV).to receive(:[]).with('action').and_return "update_person_work_email"
          allow(ENV).to receive(:[]).with('person_email').and_return "my_work1198@test.com"
          person.emails.delete_if { |email| email.kind == "work"}
          subject.migrate
          person.reload
          expect(person.emails.select { |email| email.kind == "work"}.size).to eq 1
        end
      end

      context "if you say 'no' to create a new email" do

        before do
          allow(STDIN).to receive(:gets).and_return "no"
        end

        it "should not create a new home email" do
          person.emails.delete_if { |email| email.kind == "home"}
          subject.migrate
          person.reload
          expect(person.emails.select { |email| email.kind == "home"}.size).to eq 0
        end

        it "should not create a new work email" do
          allow(ENV).to receive(:[]).with('action').and_return "update_person_work_email"
          allow(ENV).to receive(:[]).with('person_email').and_return "my_work1198@test.com"
          person.emails.delete_if { |email| email.kind == "work"}
          subject.migrate
          person.reload
          expect(person.emails.select { |email| email.kind == "work"}.size).to eq 0
        end
      end
    end

    context "update dob on person" do

      before do
        allow(ENV).to receive(:[]).with('action').and_return "person_dob"
        allow(ENV).to receive(:[]).with('dob').and_return person.dob - 4.years
      end

      it "should update the dob on the record" do
        updated_dob = person.dob - 4.years
        subject.migrate
        person.reload
        expect(person.dob).to eq updated_dob
      end

      it "should not update the dob if greater than 110 years old" do
        updated_dob = person.dob - 112.years
        allow(ENV).to receive(:[]).with('dob').and_return updated_dob
        subject.migrate
        person.reload
        expect(person.dob).not_to eq updated_dob
      end

      it "should not update the dob if it effects person match" do
        updated_dob = person.dob - 3.years
        allow(ENV).to receive(:[]).with('dob').and_return updated_dob
        allow(Person).to receive(:match_by_id_info).and_return [double("Person")]
        subject.migrate
        person.reload
        expect(person.dob).not_to eq updated_dob
      end

      context "person with employee_role" do
        let(:person) { FactoryGirl.create(:person, :with_employee_role)}

        it "should not update the dob if the census record already linked" do
          updated_dob = person.dob - 3.years
          allow(ENV).to receive(:[]).with('dob').and_return updated_dob
          subject.migrate
          person.reload
          expect(person.dob).not_to eq updated_dob
        end
      end
    end
  end
end