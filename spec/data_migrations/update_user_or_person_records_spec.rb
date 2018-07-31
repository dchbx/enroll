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

  describe "update username & email on user and also destroying headless user", dbclean: :after_each do
    let!(:person) { FactoryGirl.create(:person, hbx_id: "1234", user: user) }
    let!(:user) { FactoryGirl.create(:user) }

    before :each do
      ['action', 'user_email', 'person_email', 'user_name', 'headless_user', 'find_user_by', 'hbx_id', 'new_user_email', 'new_user_name', 'dob' ].each do |var|
        ENV[var] = nil
      end
    end

    it "should update the username on the user" do
      ENV['action'] = "update_username"
      ENV['user_name'] = "UpdatE@This"
      ENV['hbx_id'] = "1234"
      subject.migrate
      user.reload
      expect(user.oim_id).to eq "UpdatE@This"
    end

    it "should update the email on the user" do
      ENV['action'] = "update_email"
      ENV['user_email'] = "updatingemail@gmail.com"
      ENV['find_user_by'] = "user_name"
      ENV['user_name'] = user.oim_id
      subject.migrate
      user.reload
      expect(user.email).to eq "updatingemail@gmail.com"
    end

    it "should not destroy user record by oim_id if it's not headless" do
      ENV['find_user_by'] = "user_name"
      ENV['headless_user'] = "yes"
      ENV['user_name'] = user.oim_id
      subject.migrate
      expect(User.where(oim_id: user.oim_id).present?).to eq true
    end

    it "should destroy the headless user by user email" do
      ENV['find_user_by'] = "email"
      ENV['headless_user'] = "yes"
      ENV['user_email'] = user.email
      user.person.destroy!
      subject.migrate
      expect(User.where(email: user.email).present?).to eq false
    end

    it "should update the home email on person record" do
      ENV['action'] = "update_person_home_email"
      ENV['person_email'] = "my_home1198@test.com"
      ENV['hbx_id'] = person.hbx_id
      subject.migrate
      person.reload
      home_email = person.emails.detect { |email| email.kind == "home"}
      expect(home_email.address).to eq "my_home1198@test.com"
    end

    it "should update the work email on person record using oim_id" do
      ENV['hbx_id'] = person.hbx_id
      ENV['user_name'] = user.oim_id
      ENV['action'] = "update_person_work_email"
      ENV['person_email'] = "my_work1198@test.com"
      person.emails.first.update_attributes(kind: "work")
      subject.migrate
      person.reload
      work_email = person.emails.detect { |email| email.kind == "work"}
      expect(work_email.address).to eq "my_work1198@test.com"
    end

    context "create email record on person" do
      context "if you say 'yes' to create a new email" do
        before do
          allow(STDIN).to receive(:gets).and_return "yes"
          ENV['hbx_id'] = person.hbx_id
          ENV['person_email'] = "my_work1198@test.com"
        end

        it "should create a new home email" do
          ENV['action'] = "update_person_home_email"
          person.emails.delete_if { |email| email.kind == "home"}
          subject.migrate
          person.reload
          expect(person.emails.select { |email| email.kind == "home"}.size).to eq 1
        end

        it "should create a new work email" do
          ENV['action'] =  "update_person_work_email"
          person.emails.delete_if { |email| email.kind == "work"}
          subject.migrate
          person.reload
          expect(person.emails.select { |email| email.kind == "work"}.size).to eq 1
        end
      end

      context "if you say 'no' to create a new email" do
        before do
          allow(STDIN).to receive(:gets).and_return "no"
          ENV['person_email'] = "my_work1198@test.com"
        end

        it "should not create a new home email" do
          person.emails.delete_if { |email| email.kind == "home"}
          subject.migrate
          person.reload
          expect(person.emails.select { |email| email.kind == "home"}.size).to eq 0
        end

        it "should not create a new work email" do
          ENV['action'] =  "update_person_work_email"
          person.emails.delete_if { |email| email.kind == "work"}
          subject.migrate
          person.reload
          expect(person.emails.select { |email| email.kind == "work"}.size).to eq 0
        end
      end

      context "update dob on person" do
        let(:birthday) { (person.dob - 4.years) }
        let(:wrong_birthday) { (person.dob - 3.years)}
        let(:too_old) { (person.dob - 112.years) }

        before do
          ENV['action'] = "person_dob"
          ENV['dob'] = birthday.strftime('%d/%m/%Y')
          ENV['hbx_id'] = person.hbx_id
        end

        it "should update the dob on the record" do
          updated_dob = birthday
          subject.migrate
          person.reload
          expect(person.dob).to eq updated_dob
        end

        it "should not update the dob if greater than 110 years old" do
          updated_dob = too_old
          ENV['dob'] = updated_dob.strftime('%d/%m/%Y')
          subject.migrate
          person.reload
          expect(person.dob).not_to eq updated_dob
        end

        it "should not update the dob if it effects person match" do
          updated_dob = wrong_birthday
          ENV['dob'] = updated_dob.strftime('%d/%m/%Y')
          allow(Person).to receive(:match_by_id_info).and_return [double("Person")]
          subject.migrate
          person.reload
          expect(person.dob).not_to eq updated_dob
        end

        context "person with employee_role" do
          let(:person) { FactoryGirl.create(:person, :with_employee_role)}

          it "should not update the dob if the census record already linked" do
            updated_dob = wrong_birthday
            ENV['dob'] = updated_dob.strftime('%d/%m/%Y')
            subject.migrate
            person.reload
            expect(person.dob).not_to eq updated_dob
          end
        end
      end
    end
  end
end
