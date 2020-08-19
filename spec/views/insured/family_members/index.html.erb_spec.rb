require 'rails_helper'

describe "insured/family_members/index.html.erb" do
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user, person: person) }
  let(:family) { Family.new }
  let(:family_member) { family.family_members.new }
  let(:dependent) { Forms::FamilyMember.new(family_id: family.id) }
  let(:employee_role) { FactoryGirl.build(:employee_role) }
  let(:consumer_role) { FactoryGirl.build(:consumer_role) }

  before :each do
    sign_in user
    assign :person, person
    assign :family, family
    allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
  end

  it "should have title" do
    render template: "insured/family_members/index.html.erb", locals: { :group_selection_url => new_insured_group_selection_path(person_id: person.id, consumer_role_id: employee_role.id) }
    expect(rendered).to have_selector("h2", text: 'Household Info: Family Members')
  end

  it "should have memo to indicate required fields" do
    render template: "insured/family_members/index.html.erb", locals: { :group_selection_url => new_insured_group_selection_path(person_id: person.id, consumer_role_id: employee_role.id) }
    expect(rendered).to have_selector('p.memo', text: '* = required field')
  end

  context "when employee" do
    before :each do
      assign :type, "employee"
      assign :employee_role, employee_role
      render template: "insured/family_members/index.html.erb", locals: { :group_selection_url => new_insured_group_selection_path(person_id: person.id, employee_role_id: employee_role.id) }
    end

    it "should call signup_progress" do
      expect(rendered).to match /Employer/
    end
  end

  context "when consumer" do
    before :each do
      assign :type, "consumer"
      assign :consumer_role, consumer_role
      allow(view).to receive(:is_under_open_enrollment?).and_return false
      render template: "insured/family_members/index.html.erb", locals: { :group_selection_url => new_insured_group_selection_path(person_id: person.id, consumer_role_id: consumer_role.id) }
    end

    it "should call individual_progress" do
      expect(rendered).to match /Verify Identity/
      expect(rendered).to have_selector("a[href='/insured/families/find_sep?consumer_role_id=#{consumer_role.id}']", text: 'Continue')
    end
  end
end
