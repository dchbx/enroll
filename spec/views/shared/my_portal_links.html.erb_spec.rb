require 'rails_helper'

describe "shared/_my_portal_links.html.haml" do
  before :each do

  end

  context "with employee role" do
    let(:user) { FactoryGirl.create(:user, person: person, roles: ["employee"]) }
    let(:person) { FactoryGirl.create(:person, :with_employee_role)}

    it "should have one portal link" do
      all_er_profile = FactoryGirl.create(:employer_profile)
      all_census_ee = FactoryGirl.create(:census_employee, employer_profile: all_er_profile)
      person.employee_roles.first.census_employee = all_census_ee
      person.employee_roles.first.save!
      sign_in(user)
      render 'shared/my_portal_links'
      expect(rendered).to have_content('My Insured Portal')
      expect(rendered).to_not have_selector('dropdownMenu1')
    end

  end

  context "with employer role & employee role" do
    let(:user) { FactoryGirl.create(:user, person: person, roles: ["employee", "employer_staff"]) }
    let(:person) { FactoryGirl.create(:person, :with_employee_role, :with_employer_staff_role)}

    it "should have two portal links and popover" do
      all_er_profile = FactoryGirl.create(:employer_profile)
      all_census_ee = FactoryGirl.create(:census_employee, employer_profile: all_er_profile)
      person.employee_roles.first.census_employee = all_census_ee
      person.employee_roles.first.save!
      sign_in(user)
      render 'shared/my_portal_links'
      expect(rendered).to have_content('My Insured Portal')
      expect(rendered).to have_content(all_er_profile.legal_name)
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to have_selector('.dropdown[data-toggle="popover"]')
      expect(rendered).to match(/Insured/)
    end
  end

  context "with employer roles & employee role" do
    let(:user) { FactoryGirl.create(:user, person: person, roles: ["employee", "employer_staff"]) }
    let(:person) { FactoryGirl.create(:person, :with_employee_role, :with_employer_staff_role)}

    it "should have two portal links and popover" do
      all_er_profile = FactoryGirl.create(:employer_profile)
      all_er_profile.organization.update_attributes(legal_name: 'Second Company') # not always Turner
      all_census_ee = FactoryGirl.create(:census_employee, employer_profile: all_er_profile)
      EmployerStaffRole.create(person:person, employer_profile_id: all_er_profile.id)
      person.employee_roles.first.census_employee = all_census_ee
      person.employee_roles.first.save!
      sign_in(user)
      render 'shared/my_portal_links'
      expect(rendered).to have_content('My Insured Portal')
      expect(rendered).to have_content(all_er_profile.legal_name)
      expect(rendered).to have_content('Second Company')
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to have_selector('.dropdown[data-toggle="popover"]')
      expect(rendered).to match(/Insured/)
    end
  end

end
