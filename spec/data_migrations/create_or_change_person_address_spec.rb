require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "create_or_change_person_address")

describe CreateOrChangePersonAddress do

  let(:given_task_name) { "create_or_change_person_address" }
  subject { CreateOrChangePersonAddress.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "creating a new address for person with no address", dbclean: :after_each do
    let(:person) { FactoryBot.create(:person) }
    around do |example|
      ClimateControl.modify hbx_id: person.hbx_id,
                            address_kind: 'home',
                            address_1: "123 Main Street",
                            city: "Gotham",
                            state_code: 'DC',
                            zip: "30495" do
        example.run
      end
    end

    before do
      person.addresses.destroy_all
    end

    it "should create a new phone number" do
      address = person.addresses.first
      expect(address).to eq(nil)
      subject.migrate
      person.reload
      address = person.addresses.first
      expect(address.address_1).to eq('123 Main Street')
    end
  end
  describe "changing a person with existing address" do
    let(:person) { FactoryBot.create(:person, :with_mailing_address) }
    around do |example|
      ClimateControl.modify hbx_id: person.hbx_id,
                            address_kind: 'home',
                            address_1: "123 Main Street",
                            city: "Gotham",
                            state_code: 'DC',
                            zip: "30495" do
        example.run
      end
    end

    it "should create a new phone number" do
      expect(person.addresses.present?).to eq(true)
      subject.migrate
      person.reload
      expect(person.addresses.where(kind: "mailing").present?).to eq(true)
      home_address = person.addresses.where(kind: "home").first
      expect(home_address.address_1).to eq('123 Main Street')
    end
  end
end
