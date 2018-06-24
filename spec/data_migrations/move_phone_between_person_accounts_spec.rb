require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "move_phone_between_person_accounts")
describe MovePhoneBetweenPersonAccounts do
  let(:given_task_name) { "move_phone_between_person_accounts" }
  subject { MovePhoneBetweenPersonAccounts.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "move the phone from person1 to person2 " do
    let(:person1) { FactoryGirl.create(:person)}
    let(:phone) {FactoryGirl.create(:phone,:for_testing, person:person1)}
    let(:person2){FactoryGirl.create(:person)}
    before(:each) do
      allow(ENV).to receive(:[]).with("from_hbx_id").and_return(person1.hbx_id)
      allow(ENV).to receive(:[]).with("to_hbx_id").and_return(person2.hbx_id)
      allow(ENV).to receive(:[]).with("phone_id").and_return(phone.id.to_s)
    end
    it "should move user from person1 to person2" do
      phone_1=person1.phones.size
      phone_2=person2.phones.size
      subject.migrate
      person1.reload
      person2.reload
      expect(person1.phones.size).to eq phone_1
      expect(person2.phones.size).to eq phone_2+1
    end
  end
  describe "not move the phone if no_phone was given" do
    let(:person1) { FactoryGirl.create(:person)}
    let(:phone) {FactoryGirl.create(:phone,:for_testing, person:person1)}
    let(:person2){FactoryGirl.create(:person)}
    before(:each) do
      allow(ENV).to receive(:[]).with("from_hbx_id").and_return(person1.hbx_id)
      allow(ENV).to receive(:[]).with("to_hbx_id").and_return(person2.hbx_id)
      allow(ENV).to receive(:[]).with("phone_id").and_return("")
    end
    it "should move user from person1 to person2" do
      phone_1=person1.phones.size
      phone_2=person2.phones.size
      subject.migrate
      person1.reload
      person2.reload
      expect(person1.phones.size).to eq phone_1
      expect(person2.phones.size).to eq phone_2
    end
  end
  describe "not move the phone if person1's hbx_id missing" do
    let(:person1) { FactoryGirl.create(:person)}
    let(:phone) {FactoryGirl.create(:phone,:for_testing, person:person1)}
    let(:person2){FactoryGirl.create(:person)}
    before(:each) do
      allow(ENV).to receive(:[]).with("from_hbx_id").and_return("")
      allow(ENV).to receive(:[]).with("to_hbx_id").and_return(person2.hbx_id)
      allow(ENV).to receive(:[]).with("phone_id").and_return(phone.id)
    end
    it "should move user from person1 to person2" do
      phone_1=person1.phones.size
      phone_2=person2.phones.size
      subject.migrate
      person1.reload
      person2.reload
      expect(person1.phones.size).to eq phone_1
      expect(person2.phones.size).to eq phone_2
    end
  end
  describe "not move the phone if person2's hbx_id missing" do
    let(:person1) { FactoryGirl.create(:person)}
    let(:phone) {FactoryGirl.create(:phone,:for_testing, person:person1)}
    let(:person2){FactoryGirl.create(:person)}
    before(:each) do
      allow(ENV).to receive(:[]).with("from_hbx_id").and_return(person1.hbx_id)
      allow(ENV).to receive(:[]).with("to_hbx_id").and_return("")
      allow(ENV).to receive(:[]).with("phone_id").and_return(phone.id)
    end
    it "should move user from person1 to person2" do
      phone_1=person1.phones.size
      phone_2=person2.phones.size
      subject.migrate
      person1.reload
      person2.reload
      expect(person1.phones.size).to eq phone_1
      expect(person2.phones.size).to eq phone_2
    end
  end
end
