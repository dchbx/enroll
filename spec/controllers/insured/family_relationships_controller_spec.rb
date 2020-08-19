require 'rails_helper'

RSpec.describe Insured::FamilyRelationshipsController, dbclean: :after_each do
  let(:user) { instance_double("User", :primary_family => test_family, :person => person) }
  let(:test_family) { FactoryGirl.build(:family, :with_primary_family_member) }
  let(:person) { test_family.primary_family_member.person }
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: employer_profile, person: person ) }
  let(:employee_role_id) { employee_role.id }

  describe "GET index" do
    context 'normal' do
      before(:each) do
        allow(user).to receive(:person).and_return(person)
        allow(@controller).to receive(:set_family)
        @controller.instance_variable_set(:@person, person)
        @controller.instance_variable_set(:@family, test_family)
        allow(test_family).to receive(:build_relationship_matrix).and_return([])
        allow(test_family).to receive(:find_missing_relationships).and_return([])
        sign_in(user)
        get :index, :employee_role_id => employee_role_id
      end

      it "renders the 'index' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("index")
      end

      it "assigns the person" do
        expect(assigns(:person)).to eq person
      end

      it "assigns the family" do
        expect(assigns(:family)).to eq test_family
      end
    end
  end

  describe "POST create" do
    let(:test_family) { FactoryGirl.create(:family, :with_primary_family_member) }
    let(:family_member1) {FactoryGirl.create(:family_member, family: test_family).person}
    let(:primary_member) {test_family.primary_applicant.person}


    before :each do
      sign_in(user)
      allow(@controller).to receive(:set_family)
      @controller.instance_variable_set(:@person, person)
      @controller.instance_variable_set(:@family, test_family)
      post :create, :predecessor_id => family_member1.id, :successor_id => primary_member.id, :kind => "spouse", :redirect_url => insured_family_relationships_path
    end

    describe "with valid inputs" do
      it "should create relation" do
        family_member1.add_relationship(primary_member, "spouse", test_family.id)
        primary_member.add_relationship(family_member1, "spouse", test_family.id)
        expect(primary_member.person_relationships.count).to eq 1
      end

      it "should update the relationship to unrelated" do
        family_member1.add_relationship(primary_member, "unrelated", test_family.id)
        primary_member.add_relationship(family_member1, "unrelated", test_family.id)
        relationship = family_member1.person_relationships.where(:successor_id => primary_member.id, :predecessor_id => family_member1.id).first
        expect(relationship.kind).to eq "unrelated"
      end

      it "should have 2 family members" do
        expect(test_family.family_members.count).to eq 2
      end
    end

    describe "with multiple family members" do
      let(:child1) {FactoryGirl.create(:family_member, family: test_family).person}
      let(:child2) {FactoryGirl.create(:family_member, family: test_family).person}
      let(:parent1) {FactoryGirl.create(:family_member, family: test_family).person}
      let(:unrelated_member) {FactoryGirl.create(:family_member, family: test_family).person}

      it "should have relationships defined" do
        child1.add_relationship(primary_member, "child", test_family.id)
        primary_member.add_relationship(child1, "parent", test_family.id)
        child2.add_relationship(primary_member, "child", test_family.id)
        primary_member.add_relationship(child2, "parent", test_family.id)
        unrelated_member.add_relationship(primary_member, "unrelated", test_family.id)
        primary_member.add_relationship(unrelated_member, "unrelated", test_family.id)
        test_family.build_relationship_matrix
        expect(primary_member.person_relationships.count).to eq 3
      end

      it "should have 2 missing relationships" do
        child1.add_relationship(primary_member, "child", test_family.id)
        primary_member.add_relationship(child1, "parent", test_family.id)
        child2.add_relationship(primary_member, "child", test_family.id)
        primary_member.add_relationship(child2, "parent", test_family.id)
        unrelated_member.add_relationship(primary_member, "unrelated", test_family.id)
        primary_member.add_relationship(unrelated_member, "unrelated", test_family.id)
        matrix = test_family.build_relationship_matrix
        missing_rel = test_family.find_missing_relationships(matrix)
        expect(missing_rel.count).to eq 6
      end

      it "should not update any of the relationships unless in rules" do
        relationship1 = child1.person_relationships.where(:successor_id => unrelated_member.id, :predecessor_id => child1.id).first
        relationship2 = child2.person_relationships.where(:successor_id => unrelated_member.id, :predecessor_id => child2.id).first
        expect(relationship1).to eq nil
        expect(relationship2).to eq nil
      end

      it "should apply sibling relationship" do
        child1.add_relationship(primary_member, "child", test_family.id)
        primary_member.add_relationship(child1, "parent", test_family.id)
        child2.add_relationship(primary_member, "child", test_family.id)
        primary_member.add_relationship(child2, "parent", test_family.id)
        test_family.build_relationship_matrix

        relationship1 = test_family.find_existing_relationship(child1.id, child2.id, test_family.id)
        relationship2 = test_family.find_existing_relationship(child2.id, child1.id, test_family.id)

        expect(relationship1).to eq "sibling"
        expect(relationship2).to eq "sibling"
      end

      it "should apply spouse rule which updates sibling relationship" do
        child1.add_relationship(primary_member, "child", test_family.id)
        primary_member.add_relationship(child1, "parent", test_family.id)
        child2.add_relationship(family_member1, "child", test_family.id)
        family_member1.add_relationship(child2, "parent", test_family.id)
        test_family.build_relationship_matrix

        relationship1 = test_family.find_existing_relationship(child1.id, child2.id, test_family.id)
        relationship2 = test_family.find_existing_relationship(child2.id, child1.id, test_family.id)

        expect(relationship1).to eq "sibling"
        expect(relationship2).to eq "sibling"
      end

      it "should apply grandparent-grandchild rule" do
        child1.add_relationship(primary_member, "child", test_family.id)
        primary_member.add_relationship(child1, "parent", test_family.id)
        parent1.add_relationship(primary_member, "parent", test_family.id)
        primary_member.add_relationship(parent1, "child", test_family.id)
        test_family.build_relationship_matrix

        relationship1 = test_family.find_existing_relationship(child1.id, parent1.id, test_family.id)
        relationship2 = test_family.find_existing_relationship(parent1.id, child1.id, test_family.id)

        expect(relationship1).to eq "grandchild"
        expect(relationship2).to eq "grandparent"
      end

    end
  end
end
