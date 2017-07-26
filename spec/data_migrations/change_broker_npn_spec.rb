require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_broker_npn")

describe ChangeBrokerNpn, dbclean: :after_each do
  let(:given_task_name) { "change_broker_npn" }
  subject { ChangeBrokerNpn.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "change the broker role" do

    let(:broker_role) {FactoryGirl.create(:broker_role,npn:"123123")}
    before(:each) do
      allow(ENV).to receive(:[]).with("person_hbx_id").and_return(broker_role.person.hbx_id)
      allow(ENV).to receive(:[]).with("new_npn").and_return("321321")
    end
    it "should change the email of the given account" do
      expect(broker_role.npn).to eq "123123"
      subject.migrate
      broker_role.reload
      expect(broker_role.npn).to eq "321321"
    end
  end
end
