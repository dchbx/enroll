require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "delink_user_person_record")

describe DelinkUserPersonRecord do

  let(:given_task_name) { "delink user person record" }
  subject { DelinkUserPersonRecord.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "delink user person record" do

    let!(:user) { FactoryGirl.create(:user)}
    let(:person)  {FactoryGirl.create(:person,hbx_id: "1234567")}

    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(person.hbx_id)
    end

    context "delink person from user" do
      it "should delink user" do
        subject.migrate
        person.reload
        expect(person.user).to eq nil
      end
    end
  end
end
