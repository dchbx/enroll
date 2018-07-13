require "rails_helper"
if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
require File.join(Rails.root, "app", "data_migrations", "update_curam_user_records")

describe UpdateCuramUserRecords, dbclean: :after_each do

  let(:given_task_name) { "update_curam_user_records" }
  let(:curam_user) { FactoryGirl.create(:curam_user, username: 'user!123')}
  subject { UpdateCuramUserRecords.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  before do
    allow(ENV).to receive(:[]).with('action').and_return ""
    allow(ENV).to receive(:[]).with('user_email').and_return curam_user.email
    allow(ENV).to receive(:[]).with('user_name').and_return curam_user.username
    allow(ENV).to receive(:[]).with('find_user_by').and_return "email"
    allow(ENV).to receive(:[]).with('new_user_email').and_return nil
    allow(ENV).to receive(:[]).with('new_user_name').and_return nil
  end

  describe "update username & email of the curam user", dbclean: :after_each do

    it "should update the username of the user by finding user by username" do
      allow(ENV).to receive(:[]).with('action').and_return "update_UserName"
      allow(ENV).to receive(:[]).with('new_user_name').and_return "UpdatE@This"
      subject.migrate
      curam_user.reload
      expect(curam_user.username).to eq "UpdatE@This"
    end

    it "should update the email of the user by finding user by username" do
      allow(ENV).to receive(:[]).with('find_user_by').and_return "user_name"
      allow(ENV).to receive(:[]).with('new_user_email').and_return "updatingemail@gmail.com"
      allow(ENV).to receive(:[]).with('action').and_return "update_Email"
      subject.migrate
      curam_user.reload
      expect(curam_user.email).to eq "updatingemail@gmail.com"
    end

    it "should update the username of the user by finding user by email" do
      allow(ENV).to receive(:[]).with('find_user_by').and_return "email"
      allow(ENV).to receive(:[]).with('new_user_name').and_return "user@321"
      allow(ENV).to receive(:[]).with('action').and_return "update_username"
      subject.migrate
      curam_user.reload
      expect(curam_user.username).to eq "user@321"
    end

    it "should update the email of the user by finding user by email" do
      allow(ENV).to receive(:[]).with('find_user_by').and_return "email"
      allow(ENV).to receive(:[]).with('new_user_email').and_return "updatingemail@gmail.com"
      allow(ENV).to receive(:[]).with('action').and_return "update_Email"
      subject.migrate
      curam_user.reload
      expect(curam_user.email).to eq "updatingemail@gmail.com"
    end

    it "should update the dob of the user by finding user by email" do
      allow(ENV).to receive(:[]).with('find_user_by').and_return "email"
      allow(ENV).to receive(:[]).with('action').and_return "update_dob"
      allow(ENV).to receive(:[]).with('new_dob').and_return "04/04/1990"
      subject.migrate
      curam_user.reload
      expect(curam_user.dob).to eq Date.parse("04/04/1990")
    end

    it "should update the ssn of the user by finding user by email" do
      allow(ENV).to receive(:[]).with('find_user_by').and_return "email"
      allow(ENV).to receive(:[]).with('action').and_return "update_ssn"
      allow(ENV).to receive(:[]).with('new_ssn').and_return "456738293"
      subject.migrate
      curam_user.reload
      expect(curam_user.ssn).to eq "456738293"
    end
  end
end
end
