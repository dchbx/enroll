require 'rails_helper'

describe PersonRelationship, dbclean: :after_each do
  it { should validate_presence_of :relative_id }
  it { should validate_presence_of :kind }

  let(:kind) {"spouse"}
  let(:person) {FactoryGirl.create(:person )}

  describe "class methods" do
    context "shop_display_relationship_kinds" do
      let(:shop_kinds) {["spouse", "domestic_partner", "child", ""]}
    end
  end

  describe ".new" do
    let(:valid_params) do
      { kind: kind,
        relative: person,
        person: person
      }
    end

    let(:consumer_relationship_kinds) { [
        "self",
        "spouse",
        "domestic_partner",
        "child",
        "parent",
        "sibling",
        "ward",
        "guardian",
        "unrelated",
        "other_tax_dependent",
        "aunt_or_uncle",
        "nephew_or_niece",
        "grandchild",
        "grandparent"
      ] }

    let(:relationships_UI)  { [
      "self",
      "spouse",
      "domestic_partner",
      "child",
      "parent",
      "sibling",
      "unrelated",
      "aunt_or_uncle",
      "nephew_or_niece",
      "grandchild",
      "grandparent"
    ] }

    let(:kinds) {  [
      "spouse",
      "life_partner",
      "child",
      "adopted_child",
      "annuitant",
      "aunt_or_uncle",
      "brother_or_sister_in_law",
      "collateral_dependent",
      "court_appointed_guardian",
      "daughter_or_son_in_law",
      "dependent_of_a_minor_dependent",
      "father_or_mother_in_law",
      "foster_child",
      "grandchild",
      "grandparent",
      "great_grandchild",
      "great_grandparent",
      "guardian",
      "nephew_or_niece",
      "other_relationship",
      "parent",
      "sibling",
      "sponsored_dependent",
      "stepchild",
      "stepparent",
      "trustee",
      "unrelated",
      "ward"
    ] }

    context "consumer relationship dropdown list(family member page)" do
      let(:params){ valid_params.deep_merge!({kind: "other_tax_dependent"}) }

      it "consumer relationships should be matched" do
        expect(BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS).to eq consumer_relationship_kinds
      end

      it "consumer relationships displayed on UI should match" do
        expect(BenefitEligibilityElementGroup::Relationships_UI).to eq relationships_UI
      end

      it "should be valid if kind is present in person_relationship" do
        expect(PersonRelationship.new(**params).valid?).to be_truthy
      end
    end

    it "relationships should be sorted" do
      expect(PersonRelationship::Relationships).to eq kinds
    end

    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(PersonRelationship.new(**params).save).to be_falsey
      end
    end

    context "with no kind" do
      let(:params) {valid_params.except(:kind)}

      it "should fail validation " do
        expect(PersonRelationship.create(**params).errors[:kind].any?).to be_truthy
      end
    end

    context "with no relative" do
      let(:params) {valid_params.except(:relative)}

      it "should fail validation " do
        expect(PersonRelationship.create(**params).errors[:relative_id].any?).to be_truthy
      end
    end

    context "with all valid arguments" do
      let(:params) {valid_params}
      it "should save" do
        expect(PersonRelationship.new(**params).save).to be_truthy
      end
    end

    context "with all valid kinds" do
      let(:params) {valid_params}
      it "should save" do
        kinds.each do |rkind|
          params[:kind] = rkind
          expect(PersonRelationship.new(**params).save).to be_truthy
        end
      end
    end
  end
end

