require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_broker_details")

describe ChangeBrokerDetails, dbclean: :after_each do

  let(:given_task_name) {"change_broker_details"}
  let(:person) {FactoryGirl.create(:person, user: user)}
  let(:user) {FactoryGirl.create(:user)}
  let(:broker_role) {FactoryGirl.create(:broker_role, broker_agency_profile: broker_agency_profile, market_kind: 'shop')}
  let(:broker_agency_profile) {FactoryGirl.create(:broker_agency_profile, market_kind: 'shop')}

  subject {ChangeBrokerDetails.new(given_task_name, double(:current_scope => nil))}

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update broker role details" do
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return person.hbx_id
      allow(ENV).to receive(:[]).with("new_market_kind").and_return('shop')
      allow(Person).to receive(:where).and_return([person])
      allow(person).to receive(:broker_role).and_return(broker_role)
    end

    context "broker_role", dbclean: :after_each do
      it "should update broker role" do
        subject.migrate
        person.broker_role.reload
        expect(person.broker_role.market_kind).to eq "shop"
        expect(person.broker_role.broker_agency_profile.market_kind).to eq "shop"
      end
    end
  end

  describe "Validate Market Kind" do

    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return person.hbx_id
      allow(ENV).to receive(:[]).with("new_market_kind").and_return('invalid market kind')
      allow(Person).to receive(:where).and_return([person])
      allow(person).to receive(:broker_role).and_return(broker_role)
    end

    context "broker_role", dbclean: :after_each do
      it "should not update broker role market kind" do
        subject.migrate
        person.broker_role.reload
        expect(person.broker_role.market_kind).to eq "shop"
        expect(person.broker_role.broker_agency_profile.market_kind).to eq "shop"
      end
    end
  end
end
