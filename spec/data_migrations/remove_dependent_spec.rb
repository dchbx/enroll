require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_dependent")

describe RemoveDependent, dbclean: :after_each do

  let(:given_task_name) { "remove_dependent" }
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member_and_dependent)}
  subject { RemoveDependent.new(given_task_name, double(:current_scope => nil)) }

  before do
    allow(ENV).to receive(:[]).with("family_member_id").and_return(family.family_members.where(is_primary_applicant: false).first.id)
  end

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "Should not remove duplicate dependents", dbclean: :after_each do

    it "should not remove duplicate family member" do
      expect(family.family_members.size).to eq 3
      subject.migrate
      family.reload
      expect(family.family_members.size).to eq 3
    end

  end

  describe "Should remove duplicate dependents", dbclean: :after_each do
    before do
      fm = family.family_members.where(is_primary_applicant: false).first
      family.remove_family_member(fm.person)
    end

    it "should remove duplicate family member" do
      expect(family.family_members.size).to eq 3
      subject.migrate
      family.reload
      expect(family.family_members.size).to eq 2
    end
  end
end
