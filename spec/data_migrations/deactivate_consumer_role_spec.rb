require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "deactivate_consumer_role")
describe DeactivateConsumerRole do

    let(:given_task_name) { "deactivate_consumer_role" }
    subject { DeactivateConsumerRole.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do

  	it "has the given task name" do
  	  expect(subject.name).to eql given_task_name
  	end
  end

  describe "deactivate consumer role" do
  	let(:person) { FactoryGirl.create(:person, :with_consumer_role, hbx_id: "12345678")}

   before(:each) do
    allow(ENV).to receive(:[]).with("hbx_id").and_return("12345678")
   end
    
    it "should change is_active field" do
     role_status = person.consumer_role
     role_status.is_active = true
     role_status.save
     subject.migrate
     person.reload	
     expect(person.consumer_role.is_active).to eq false
    end
  end
end
