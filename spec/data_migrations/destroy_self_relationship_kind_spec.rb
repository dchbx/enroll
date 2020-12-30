# frozen_string_literal: true

require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "destroy_self_relationship_kind")

describe DestroySelfRelationshipKind, dbclean: :after_each do

  let(:given_task_name) { "destroy_self_relationship_kind" }
  subject { DestroySelfRelationshipKind.new(given_task_name, double(:current_scope => nil)) }

  context "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "person relationship kind" do
    let(:person) { FactoryBot.create(:person)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

    before(:each) do
      person.person_relationships << PersonRelationship.new(relative: person, kind: "self")
      person.save
    end

    it "should destroy" do
      ClimateControl.modify hbx_id: person.hbx_id do
        expect(person.person_relationships.where(relative_id: person.id).present?).to be_truthy
        subject.migrate
        person.reload
        expect(person.person_relationships.where(relative_id: person.id).present?).to be_falsey
      end
    end
  end
end
