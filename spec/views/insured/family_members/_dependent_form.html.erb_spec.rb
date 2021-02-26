# frozen_string_literal: true

require 'rails_helper'

describe "insured/family_members/_dependent_form.html.erb" do
  let(:person) { FactoryBot.create(:person) }
  let(:consumer_role) { FactoryBot.create(:consumer_role)}
  let(:user) { FactoryBot.create(:user, person: person) }
  let(:family) { Family.new }
  let(:family_member) { family.family_members.new }
  let(:dependent) { Forms::FamilyMember.new(family_id: family.id) }
  let(:individual_market_is_enabled) { true }

  context "with consumer_role_id" do
    before :each do
      person.consumer_role = consumer_role
      person.save
      sign_in user
      @request.env['HTTP_REFERER'] = 'consumer_role_id'
      allow(person).to receive(:is_consumer_role_active?).and_return true
      assign :person, person
      assign :dependent, dependent
      assign(:support_texts, {support_text_key: "support-text-description"})
      allow(view).to receive(:individual_market_is_enabled?).and_return(individual_market_is_enabled)
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      render "insured/family_members/dependent_form", dependent: dependent, person: person
    end

    it "should have dependent_list area" do
      expect(rendered).to have_selector("li.dependent_list")
    end

    it "should not have required for ssn" do
      expect(rendered).not_to have_selector('input[placeholder="SOCIAL SECURITY *"]')
    end

    context "when individual market is enabled" do
      let(:individual_market_is_enabled) { true }
      it "should have consumer_fields area" do
        expect(rendered).to have_css('#consumer_fields .row:first-child label', text: 'Is this person a US citizen or US national?')
        expect(rendered).to have_selector("div#consumer_fields")
        expect(rendered).to match(/Is this person a US citizen or US national/)
      end

      it "should have show tribal_container" do
        expect(rendered).to have_selector('div#tribal_container')
        expect(rendered).to have_content('Is this person a member of an American Indian or Alaska Native Tribe? *')
      end

      it "should display the is_applying_coverage field option" do
        expect(rendered).to match(/Does this person need coverage? */)
      end
    end

    context "when individual market is disabled" do
      let(:individual_market_is_enabled) { false }
      it "should have consumer_fields area" do
        expect(rendered).to_not have_css('#consumer_fields .row:first-child label', text: 'Is this person a US Citizen or US National?')
        expect(rendered).to_not have_selector("div#consumer_fields")
        expect(rendered).to_not match(/Is this person a US citizen or US National/)
      end

      it "should have show tribal_container" do
        expect(rendered).to_not have_selector('div#tribal_container')
        expect(rendered).to_not have_content('Are you a member of an American Indian or Alaska Native Tribe? *')
      end
    end

    it "should have no_ssn input" do
      expect(rendered).to have_selector('input#dependent_no_ssn')
    end

    it "should have no_ssn label" do
      expect(rendered).to have_selector('span.no_ssn')
      expect(rendered).to match(/have an SSN/)
    end

    it "should have dependent-address area" do
      expect(rendered).to have_selector("div#dependent-address")
    end

    it "should have required indicator for fields" do
      ["FIRST NAME", "LAST NAME", "DATE OF BIRTH"].each do |field|
        expect(rendered).to have_selector("input[placeholder='#{field} *']")
      end
      expect(rendered).to have_selector("option", text: "choose")
    end

    it "should have not have age off exclusion field for consumer role only" do
      expect(rendered).not_to match "Ageoff Exclusion"
      expect(rendered).not_to have_field('age_off_excluded', checked: false)
    end
  end

  context "without consumer_role" do
    before :each do
      sign_in user
      @request.env['HTTP_REFERER'] = ''
      allow(person).to receive(:is_consumer_role_active?).and_return false
      allow(person).to receive(:has_active_employee_role?).and_return true
      assign :person, person
      assign :dependent, dependent
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      render "insured/family_members/dependent_form", dependent: dependent, person: person
    end

    it "should have dependent_list area" do
      expect(rendered).to have_selector("li.dependent_list")
    end

    it "should not have consumer_fields area" do
      expect(rendered).not_to have_selector("div#consumer_fields")
      expect(rendered).not_to match(/Are you a US Citizen or US National/)
    end

    it "should not have dependent-address area" do
      expect(rendered).not_to have_selector("div#dependent-address")
      expect(rendered).not_to have_selector("div#dependent-home-address-area")
    end

    it "should have required indicator for fields" do
      ["FIRST NAME", "LAST NAME", "DATE OF BIRTH"].each do |field|
        expect(rendered).to have_selector("input[placeholder='#{field} *']")
      end
      expect(rendered).to have_selector("option", text: "choose")
    end

    it "should not display the is_applying_coverage field option" do
      expect(rendered).not_to match(/Does this person need coverage? */)
    end

    it "should display the affirmative message" do
      message = "Even if you don’t want health coverage for yourself, providing your SSN can be helpful since it can speed up the application process. We use SSNs to check income and other "\
                "information to see who’s eligible for help with health coverage costs."
      expect(rendered).not_to match(/#{message}/)
    end

    it "should have address info area" do
      expect(rendered).to have_selector('#address_info')
      expect(rendered).to match(/Home Address/)
    end

    it "should have age off exclusion field for employee role only" do
      expect(rendered).to match "Ageoff Exclusion"
      expect(rendered).to have_field('age_off_excluded', checked: false)
    end
  end

  context "user login with broker role" do

    let(:current_user) { FactoryBot.create(:user, person: person) }
    let(:employer_profile) { FactoryBot.create(:employer_profile) }
    let(:broker_agency_profile) { FactoryBot.create(:broker_agency_profile) }
    let!(:broker_role1) { FactoryBot.create(:broker_role, broker_agency_profile_id: broker_agency_profile.id, person: person) }
    let(:broker_agency_staff_role) { FactoryBot.create(:broker_agency_staff_role, aasm_state: "active", benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id)}

    before :each do
      current_user.person.broker_agency_staff_roles << broker_agency_staff_role
      sign_in(current_user)
      @request.env['HTTP_REFERER'] = ''
      allow(person).to receive(:is_consumer_role_active?).and_return false
      allow(person).to receive(:has_active_employee_role?).and_return false
      allow(person).to receive(:broker_role).and_return(broker_role1)
      assign :person, person
      assign :dependent, dependent
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      render "insured/family_members/dependent_form", dependent: dependent, person: person
    end

    it "should not have age off exclusion checbox when current user has broker role" do
      expect(rendered).not_to match "Ageoff Exclusion"
    end
  end
end
