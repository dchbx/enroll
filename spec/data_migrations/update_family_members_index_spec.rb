require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_family_members_index")

describe UpdateFamilyMembersIndex do

  let(:given_task_name) { "update_family_members_index" }
  subject { UpdateFamilyMembersIndex.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "case with if both primary_person and dependent is not present" do
    before :each do
      allow(ENV).to receive(:[]).with("primary_hbx").and_return("")
      allow(ENV).to receive(:[]).with("dependent_hbx").and_return("")
      allow(ENV).to receive(:[]).with("action_task").and_return("update_family_member_index")
    end

    context "case with if dependent not present" do
      before :each do
        allow(ENV).to receive(:[]).with("primary_hbx").and_return("1111")
        allow(ENV).to receive(:[]).with("dependent_hbx").and_return("")
        allow(ENV).to receive(:[]).with("action_task").and_return("update_family_member_index")
      end
      it "found no family with given dependent_hbx" do
        expect{subject.migrate}.to raise_error("some error person with hbx_id:1111 and hbx_id: not found")
      end
    end

    context "case with if primary_person not present" do
      before :each do
        allow(ENV).to receive(:[]).with("primary_hbx").and_return("")
        allow(ENV).to receive(:[]).with("dependent_hbx").and_return("1112")
        allow(ENV).to receive(:[]).with("action_task").and_return("update_family_member_index")
      end
      it "found no family with given primary_hbx" do
        expect{subject.migrate}.to raise_error("some error person with hbx_id: and hbx_id:1112 not found")
      end
    end
  end

  describe "update family_members index", dbclean: :after_each do

    let(:wife) { FactoryGirl.create(:person, first_name: "wifey")}
    let(:husband) { FactoryGirl.create(:person, first_name: "hubby")}
    let(:family) { FactoryGirl.build(:family) }
    let!(:husbands_family) do
      husband.person_relationships << PersonRelationship.new(kind: "spouse", relative_id: wife.id, family_id: family.id, successor_id: wife.id, predecessor_id: husband.id )
      husband.save!

      wife.person_relationships << PersonRelationship.new(kind: "spouse", relative_id: husband.id, family_id: family.id, successor_id: husband.id, predecessor_id: wife.id )
      wife.save!

      family.add_family_member(wife)
      family.add_family_member(husband, is_primary_applicant: true)
      family.save!
      family
    end

    before(:each) do
      allow(ENV).to receive(:[]).with("primary_hbx").and_return(husband.hbx_id)
      allow(ENV).to receive(:[]).with("dependent_hbx").and_return(wife.hbx_id)
      allow(ENV).to receive(:[]).with("primary_family_id").and_return(husbands_family.family_members.first.id)
      allow(ENV).to receive(:[]).with("dependent_family_id").and_return(husbands_family.family_members.second.id)
      allow(ENV).to receive(:[]).with("action_task").and_return("update_family_member_index")
    end

    it "should swap the index of family members" do
      expect(husbands_family.family_members.first.is_primary_applicant?).to eq false
      expect(husbands_family.family_members.second.is_primary_applicant?).to eq true

      subject.migrate
      husbands_family.reload
      hus_fam_id = husbands_family.family_members.first.id
      wife_fam_id = husbands_family.family_members.second.id
      expect(husbands_family.family_members.where(id: hus_fam_id).first.is_primary_applicant?).to eq true
      expect(husbands_family.family_members.where(id: wife_fam_id).first.is_primary_applicant?).to eq false
    end
  end


  describe "update family_members id", dbclean: :after_each do
    let(:person) { FactoryGirl.create(:person) }
    let(:family1) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:family_member){ FactoryGirl.create(:family_member, family: family1, is_active: true)}
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
    let(:correct_family_member){ FactoryGirl.create(:family_member,family: family, is_active: true)}
    let(:action_task) {'update_family_id'}
    before(:each) do
      allow(ENV).to receive(:[]).with('primary_hbx').and_return person.hbx_id
      allow(ENV).to receive(:[]).with('old_family_id').and_return family_member.id
      allow(ENV).to receive(:[]).with('correct_family_id').and_return correct_family_member.id
      allow(ENV).to receive(:[]).with('action_task').and_return action_task
      chms = family.households.first.coverage_households.first.coverage_household_members << CoverageHouseholdMember.new(family_member_id: family_member.id, is_subscriber: false)
    end

    context "case with if primary_person not present" do
      before :each do
        allow(ENV).to receive(:[]).with('primary_hbx').and_return person.hbx_id
        allow(ENV).to receive(:[]).with('old_family_id').and_return family_member.id
        allow(ENV).to receive(:[]).with('correct_family_id').and_return correct_family_member.id
        allow(ENV).to receive(:[]).with("action_task").and_return("update_family_id")
      end

      it "should swap the index of family members" do
        subject.migrate
        family.reload
        expect(family.households.first.coverage_households.first.coverage_household_members.where(family_member_id: correct_family_member.id)).to be_present
        expect(family.households.first.coverage_households.first.coverage_household_members.where(family_member_id: family_member.id)).to be_empty
      end
    end
  end

end
