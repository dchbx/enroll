require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_carrier_names")

describe UpdateCarrierNames, dbclean: :after_each do
  let(:given_task_name) { "update_carrier_names" }
  subject { UpdateCarrierNames.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing organization's legal name" do
    let(:organization) { FactoryGirl.create(:organization, fein: "042864973", legal_name: "Health New England, Inc.")}

    it "should update legal name for health new england" do
      expect(organization.legal_name).to eq "Health New England, Inc."
      subject.migrate
      organization.reload
      expect(organization.legal_name).to eq "Health New England"
    end
  end
end
