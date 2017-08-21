require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "updating_person_phone_number")

describe UpdatingPersonPhoneNumber, dbclean: :after_each do

  let(:given_task_name) { "update_broker_phone_kind" }
  subject { UpdatingPersonPhoneNumber.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing broker phone kind" do  
     let(:phone) {FactoryGirl.build(:phone, kind:'work')}
     let(:person) { FactoryGirl.create(:person,phones:[phone]) }


    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(person.hbx_id)
      allow(ENV).to receive(:[]).with("area_code").and_return('302')
      allow(ENV).to receive(:[]).with("number").and_return('4667333')
      allow(ENV).to receive(:[]).with("ext").and_return('')
      allow(ENV).to receive(:[]).with("full_number").and_return('3014667333')
    end

    it "should change the employee contribution" do
      subject.migrate
      person.reload
      expect(person.phones.where(kind:'work').first.full_phone_number).to eq '3014667333'
    end
  end
end
