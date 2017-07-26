require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_organization")

describe RemoveOrganization, dbclean: :after_each do

  let(:given_task_name) { "remove_organization" }
  subject { RemoveOrganization.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "deleting organization" do
    let(:organization) { FactoryGirl.create(:organization)}
    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
    end

    it "should remove organization" do
      fein=organization.fein
      expect(organization.fein).to eq fein
      subject.migrate
      expect(Organization.where(fein: fein).size).to eq 0
    end
  end
end
