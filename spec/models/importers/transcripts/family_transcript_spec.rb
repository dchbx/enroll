require 'rails_helper'

RSpec.describe Importers::Transcripts::FamilyTranscript, type: :model do

  describe "find_or_build_family" do

    let!(:spouse)  { 
      p = FactoryGirl.create(:person)
      p.person_relationships.build(relative: person, kind: "spouse")
      p.save; p
    }

    let!(:child1)  { 
      p = FactoryGirl.create(:person)
      p.person_relationships.build(relative: person, kind: "child")
      p.save; p
    }

    let!(:child2)  { 
      p = FactoryGirl.create(:person)
      p.person_relationships.build(relative: person, kind: "child")
      p.save; p
    }

    let!(:person) do
      p = FactoryGirl.build(:person)
      p.save; p
    end

    context "Family already exists" do

      let!(:source_family) { 
        family = Family.new({ hbx_assigned_id: '25112', e_case_id: "6754632" })
        family.family_members.build(is_primary_applicant: true, person: person)
        family.family_members.build(is_primary_applicant: false, person: spouse)
        family.family_members.build(is_primary_applicant: false, person: child1)
        family.save(:validate => false)
        family
      }

      let(:other_family) {
        family = Family.new({
          hbx_assigned_id: '24112',
          e_case_id: "6754632"
          })
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
        person.person_relationships.build(relative: spouse, kind: "spouse")
        person.person_relationships.build(relative: child1, kind: "child")
        person.person_relationships.build(relative: child2, kind: "child")
        person.save!
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
