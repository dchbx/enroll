require 'rails_helper'

RSpec.describe Importers::Transcripts::FamilyTranscript, type: :model do

  describe "find_or_build_family" do

    let(:spouse) { FactoryGirl.create(:person)}
    let(:child1) { FactoryGirl.create(:person)}
    let(:person) { FactoryGirl.create(:person)}
    let(:child2) { FactoryGirl.create(:person)}

    context "Family already exists" do

      let!(:source_family) { 
        family = Family.new({ hbx_assigned_id: '25112', e_case_id: "6754632" })
        family.family_members.build(is_primary_applicant: true, person: person)
        family.family_members.build(is_primary_applicant: false, person: spouse)
        family.family_members.build(is_primary_applicant: false, person: child1)
        family.save(:validate => false)
        person.person_relationships.create(predecessor_id: person.id , successor_id: spouse.id, kind: "spouse", family_id: family.id)
        person.person_relationships.create(predecessor_id: person.id , successor_id: child1.id, kind: "parent", family_id: family.id)
        person.person_relationships.create(predecessor_id: person.id , successor_id: child2.id, kind: "parent", family_id: family.id)
        family
      }

      let(:other_family) {
        family = Family.new({
          hbx_assigned_id: '24112',
          e_case_id: "6754632"
          })
        person.person_relationships.create(predecessor_id: person.id , successor_id: child1.id, kind: "parent", family_id: family.id)
        person.person_relationships.create(predecessor_id: person.id , successor_id: child2.id, kind: "parent", family_id: family.id)
        family.family_members.build(is_primary_applicant: true, person: person)
        family.family_members.build(is_primary_applicant: false, person: child1)
        family.family_members.build(is_primary_applicant: false, person: child2)
        family.irs_groups.build(hbx_assigned_id: '651297232112', effective_starting_on: Date.new(2016,1,1), effective_ending_on: Date.new(2016,12,31), is_active: true)
        family
      }

      def build_transcript
       factory = Transcripts::FamilyTranscript.new
       factory.find_or_build(other_family)
       factory.transcript
      end

      def build_person_relationships
        person.person_relationships.build(successor_id: spouse.id, predecessor_id: person.id, kind: "spouse", family_id: source_family.id)
        person.person_relationships.build(successor_id: child1.id, predecessor_id: person.id, kind: "parent", family_id: source_family.id)
        person.person_relationships.build(successor_id: child2.id, predecessor_id: person.id, kind: "parent", family_id: source_family.id)
        person.save!
        spouse.person_relationships.create(successor_id: person.id, predecessor_id: spouse.id, kind: "spouse", family_id: source_family.id)
        child1.person_relationships.create(successor_id: person.id, predecessor_id: child1.id, kind: "child", family_id: source_family.id)
        child2.person_relationships.create(successor_id: person.id, predecessor_id: child2.id, kind: "child", family_id: source_family.id)
      end

      def change_relationship
        child1.person_relationships.first.update_attributes(kind: 'spouse')
      end

      # context "and dependent family member missing" do

      #   it 'should have add on dependnet' do
      #     build_person_relationships
      #     transcript = build_transcript

      #     family_importer = Importers::Transcripts::FamilyTranscript.new
      #     family_importer.transcript = transcript
      #     family_importer.market = 'individual'
      #     family_importer.other_family = other_family
      #     family_importer.process
      #   end
      # end

      context "and dependent relation changed" do

        it 'should have add on dependnet' do
          build_person_relationships
          change_relationship

          transcript = build_transcript

          family_importer = Importers::Transcripts::FamilyTranscript.new
          family_importer.transcript = transcript
          family_importer.market = 'individual'
          family_importer.other_family = other_family
          family_importer.process

        end
      end
    end
  end
end
