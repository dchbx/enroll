require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_user_email")

describe UpdateUserEmail do

  before(:all) do
    @file = File.join(Rails.root, 'spec', 'test_data', 'update_user_email.xlsx')
    @result = Roo::Spreadsheet.open(@file)
  end

  describe "given a task name" do
    let(:given_task_name) { "update_user_email" }
    subject { UpdateUserEmail.new(given_task_name, double(:current_scope => nil)) }

    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "#migrate" do
    subject { UpdateUserEmail.new("fix me task", double(:current_scope => nil)) }

    context "user oim_id found" do
      let(:user) { FactoryGirl.create(:user, oim_id:'username1', email:'') }
      before :each do
        allow(File).to receive(:exists?).and_return(true)
        allow(Roo::Spreadsheet).to receive(:open).and_return(@result)
        user.reload
        subject.migrate
      end
      it "user email updated" do
        user.reload
        expect(user.email).to eq @result.row(2)[1]
      end
    end

    context "user oim_id not found " do
      let(:user1) { FactoryGirl.create(:user, oim_id:'username10',email:'test@gmail.com') }
      before :each do
        allow(File).to receive(:exists?).and_return(true)
        allow(Roo::Spreadsheet).to receive(:open).and_return(@result)
        subject.migrate
      end
      it "user email not updated" do
        user1.reload
        expect(user1.email).to eq 'test@gmail.com'
      end
    end
  end
end
