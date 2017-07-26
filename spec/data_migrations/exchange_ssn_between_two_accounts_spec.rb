require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "exchange_ssn_between_two_accounts")
describe ChangeFein do
  let(:given_task_name) { "exchange_ssn_between_two_accounts" }
  subject { ExchangeSsnBetweenTwoAccounts.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "change ssn if both people exits and both have ssn" do
    let(:person1){ FactoryGirl.create(:person,ssn:"123123123")}
    let(:person2){FactoryGirl.create(:person,ssn:"456456456")}

    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id_1").and_return(person1.hbx_id)
      allow(ENV).to receive(:[]).with("hbx_id_2").and_return(person2.hbx_id)
    end
    after(:each) do
      DatabaseCleaner.clean
    end

    it "should change ssn of two people" do
      ssn1=person1.ssn
      ssn2=person2.ssn
      subject.migrate
      person1.reload
      person2.reload
      expect(person2.ssn).to eq ssn1
      expect(person1.ssn).to eq ssn2
    end
  end
  describe "not change ssn if either people not exist" do
    let(:person1){ FactoryGirl.create(:person,ssn:"123123123")}
    let(:person2){FactoryGirl.create(:person,ssn:"456456456")}

    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id_1").and_return("")
      allow(ENV).to receive(:[]).with("hbx_id_2").and_return(person2.hbx_id)
    end
    after(:each) do
      DatabaseCleaner.clean
    end
    it "should change ssn of two people" do
      ssn1=person1.ssn
      ssn2=person2.ssn
      subject.migrate
      person1.reload
      person2.reload
      expect(person1.ssn).to eq ssn1
      expect(person2.ssn).to eq ssn2
    end
  end
  describe "not change ssn if either people has no ssn" do
    let(:person1){ FactoryGirl.create(:person,ssn:"123123123")}
    let(:person2){FactoryGirl.create(:person)}

    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id_1").and_return(person1.hbx_id)
      allow(ENV).to receive(:[]).with("hbx_id_2").and_return(person2.hbx_id)
    end
    after(:each) do
      DatabaseCleaner.clean
    end
    it "should change ssn of two people" do
      ssn1=person1.ssn
      ssn2=person2.ssn
      subject.migrate
      person1.reload
      person2.reload
      expect(person1.ssn).to eq ssn1
      expect(person2.ssn).to eq ssn2
    end
  end
end
