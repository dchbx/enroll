require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_dependent")

describe RemoveDependent, dbclean: :after_each do

  let(:given_task_name) { "remove_dependent" }
  subject { RemoveDependent.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "add family member to coverage household", dbclean: :after_each do

    let(:person) { FactoryGirl.create(:person) }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:family_member){FactoryGirl.create(:family_member, family: family,is_primary_applicant: false, is_active: true)}

    before do
      allow(ENV).to receive(:[]).with("family_member_id").and_return(family_member.id)
      allow(person).to receive(:primary_family).and_return(family)
    end

    it "should remove duplicate family member" do
      family_member_id=family_member.id
      expect(person.primary_family.family_members.where(id:family_member_id).size).to eq 1     
      subject.migrate 
      family.reload
      expect(person.primary_family.family_members.where(id:family_member_id).size).to eq 0
    end
  end
end
