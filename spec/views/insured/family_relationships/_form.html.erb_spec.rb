require "rails_helper"
include ActionView::Context
RSpec.describe "insured/family_relationships/_form.html.erb" do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
  let(:test_family) {FactoryGirl.create(:family, :with_primary_family_member, person: person)}
  let(:relationship_kinds) {PersonRelationship::Relationships_UI}
  let(:child) {FactoryGirl.create(:family_member, :family => test_family).person}
  let(:unrelated_member) {FactoryGirl.create(:family_member, :family => test_family).person}
  let!(:missing_relationships){ [{child.id => unrelated_member.id}]}
  let!(:all_relationships) { test_family.find_all_relationships(test_family.build_relationship_matrix) }

  before :each do
    assign(:family, test_family)
    render partial: "insured/family_relationships/form", locals: {form_remote: false, all_relationships: all_relationships, missing_relationships: missing_relationships, relationship_kinds: relationship_kinds, family: test_family, redirect_url: ""}
  end

  it "should have title" do
    expect(rendered).to match /Family Relationships/
  end

  it "should render form with missing relationship questions" do
    expect(rendered).to have_css('div.missing_relation')
  end

  it "should not display the message" do
    expect(rendered).not_to match /All the relationships are added/
  end

  it "should display family member's name" do
    child_name = child.full_name
    unrelated_name = unrelated_member.full_name
    expect(rendered).to match child_name
    expect(rendered).to match unrelated_name
  end

  describe "without any missing relationships for the family" do
    let!(:missing_relationships2) {[]}
    let!(:all_relationships2) {
      all_relationships.each do |relation|
        relation[:relation] = PersonRelationship::Relationships_UI.sample
      end
      all_relationships
    }

    before :each do
      render partial: "insured/family_relationships/form", locals: {form_remote: false, all_relationships: all_relationships2, missing_relationships: missing_relationships2, relationship_kinds: relationship_kinds, family: test_family, redirect_url: ""}
    end

    it "should display message if all relationships are defined" do
      expect(rendered).to match /Family Relationships/
      expect(rendered).to have_css('div.household')
    end
  end
end
