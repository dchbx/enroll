require 'rails_helper'

describe Parsers::Xml::Cv::Importers::FamilyParser do
  let(:subject) { Parsers::Xml::Cv::Importers::FamilyParser.new(xml) }

  context "valid verified_family" do
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "importer_payloads", "family.xml")) }

    context "get_family_object" do
      it 'should return the family as an object' do
        expect(subject.get_family_object.class).to eq Family
      end

      it "should get e_case_id" do
        expect(subject.get_family_object.e_case_id).to eq "abc123xyz2"
      end

      it "should get family_members" do
        family = subject.get_family_object
        expect(family.family_members.class).to eq Array
        expect(family.family_members.length).to eq 2
      end

      it "should get is_primary_applicant by family_members" do
        family_member = subject.get_family_object.family_members.first
        expect(family_member.is_primary_applicant).to eq true
      end

      it "should get is_coverage_applicant by family_member" do
        family_member = subject.get_family_object.family_members.last
        expect(family_member.is_coverage_applicant).to eq false
      end

      it "should get relationship by person" do
        person = subject.get_family_object.family_members.last.person
        expect(person.person_relationships.first.kind).to eq 'parent'
      end

      it "should get person info by family_members" do
        person = subject.get_family_object.family_members.first.person
        expect(person.first_name).to eq "Michael"
        expect(person.middle_name).to eq "J"
        expect(person.last_name).to eq "Green"
      end

      it "should get households" do
        family = subject.get_family_object
        expect(family.households.class).to eq Array
      end

      it "should get irs_groups" do
        family = subject.get_family_object
        expect(family.irs_groups.class).to eq Array
      end

      it "should get coverage_households by household" do
        household = subject.get_family_object.households.first
        expect(household.coverage_households.class).to eq Array
      end

      it "should get tax_households by household" do
        household = subject.get_family_object.households.first
        expect(household.tax_households.class).to eq Array
      end

      it "should get tax_household_members by tax_households" do
        household = subject.get_family_object.households.first
        expect(household.tax_households.first.tax_household_members.class).to eq Array
      end

      it "should get relationship by family_members" do
        family_members = subject.get_family_object.family_members
        expect(family_members.map(&:primary_relationship)).to eq ['self', 'parent']
      end

      it "person should have relationships" do
        family_members = subject.get_family_object.family_members
        family_members.each do |fm|
          expect(fm.person.person_relationships.length).to be > 0
        end
      end

      it "should get person_relationships by primary_applicant" do
        person = subject.get_family_object.primary_applicant.person
        expect(person.person_relationships.length).to eq 1
      end

      it "should get timestamps" do
        family = subject.get_family_object
        expect(family.created_at.present?).to eq true
        expect(family.updated_at.present?).to eq true
      end
    end
  end
end
