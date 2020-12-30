require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_invalid_address_for_person")

describe RemoveInvalidAddressForPerson, dbclean: :after_each do

  let(:given_task_name) {"remove_invalid_address_for_person"}
  let(:person) {FactoryBot.create(:person)}
  let(:invalid_address) {FactoryBot.create(:address, kind: "home", person: person)}
  let!(:valid_params) {{person_hbx_id: person.hbx_id, address_id: invalid_address.id.to_s}}
  let!(:invalid_params) {{person_hbx_id: "1234", address_id: invalid_address.id.to_s}}
  let!(:invalid_address_params) {{person_hbx_id: person.hbx_id, address_id: "1234"}}

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end

  subject {RemoveInvalidAddressForPerson.new(given_task_name, double(:current_scope => nil))}

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eq given_task_name
    end
  end

  describe "remove_invalid_address_for_person" do

    it "should remove invalid address for the person" do
      expect(person.addresses.size).to eq 3
      with_modified_env valid_params do
        subject.migrate
        person.reload
        expect(person.addresses.size).to eq 2
      end
    end

    it "should raise an error message if person record not found" do
      with_modified_env invalid_params do
        expect{subject.migrate}.to raise_error(RuntimeError, "Person not found for HBX ID #{invalid_params[:person_hbx_id]}. Please provide valid one")
      end
    end

    it "should raise an error message if address record not found" do
      with_modified_env invalid_address_params do
        expect{subject.migrate}.to raise_error(RuntimeError, "No address record found for the person")
      end
    end
  end
end
