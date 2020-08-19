require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "relationships_update")


describe RelationshipsUpdate do
  let(:given_task_name) { "relationships_update" }
  subject { RelationshipsUpdate.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end


  describe "mike's family with relationships" do
    let(:mike) { FactoryGirl.create(:person, first_name: "mike") }
    let(:carol) { FactoryGirl.create(:person, first_name: "carol") }
    let(:greg) { FactoryGirl.create(:person, first_name: "greg") }
    let(:jan) { FactoryGirl.create(:person, first_name: "jan") }
    let!(:mikes_family) do
      family = FactoryGirl.build(:family)
      mike.person_relationships << PersonRelationship.new(relative_id: carol.id, kind: "spouse", predecessor_id: mike.id, :successor_id => carol.id, family_id: family.id)
      mike.person_relationships << PersonRelationship.new(relative_id: greg.id, kind: "child", predecessor_id: mike.id, :successor_id => greg.id, family_id: family.id)
      mike.person_relationships << PersonRelationship.new(relative_id: jan.id, kind: "child", predecessor_id: mike.id, :successor_id => jan.id, family_id: family.id)
      mike.save

      family.family_members = [
            FactoryGirl.build(:family_member, family: family, person: mike, is_primary_applicant: true),
            FactoryGirl.build(:family_member, family: family, person: carol, is_primary_applicant: false),
            FactoryGirl.build(:family_member, family: family, person: greg, is_primary_applicant: false),
            FactoryGirl.build(:family_member, family: family, person: jan, is_primary_applicant: false)
           ]
      family.save
      family
    end

    it "should add/update relationships from the context of both primary and dependent" do
      expect(mikes_family.valid?).to eq true
      expect(mike.person_relationships.where(relative_id: carol.id).first.kind).to eq "spouse"
      expect(mike.person_relationships.where(relative_id: greg.id).first.kind).to eq "child"
      expect(mike.person_relationships.where(relative_id: jan.id).first.kind).to eq "child"
      subject.migrate
      mike.reload
      carol.reload
      greg.reload
      jan.reload
      mike_greg = mike.person_relationships.where(predecessor_id: mike.id, successor_id: greg.id).first.kind
      mike_jan = mike.person_relationships.where(predecessor_id: mike.id, successor_id: jan.id).first.kind
      carol_mike = carol.person_relationships.where(predecessor_id: carol.id, successor_id: mike.id).first.kind
      greg_mike = greg.person_relationships.where(predecessor_id: greg.id, successor_id: mike.id).first.kind
      jan_mike = jan.person_relationships.where(predecessor_id: jan.id, successor_id: mike.id).first.kind
      expect(mike_greg).to eq "parent"
      expect(mike_jan).to eq "parent"
      expect(carol_mike).to eq "spouse"
      expect(greg_mike).to eq "child"
      expect(jan_mike).to eq "child"
    end
  end
end