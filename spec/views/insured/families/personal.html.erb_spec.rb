require 'rails_helper'

RSpec.describe "insured/families/personal.html.erb" do
  before :each do
    stub_template "ui-components/v1/navs/families_navigation" => ''
    stub_template "insured/families/_profile_submenu.html.erb" => ''
    stub_template 'devise/passwords/_edit.html.erb' => ''
    stub_template 'users/security_question_responses/_edit_modal.html.erb' => ''
    assign(:person, person)
    sign_in(current_user)
    allow(person).to receive_message_chain("primary_family.current_broker_agency.present?").and_return(false)
    allow(view).to receive(:enrollment_group_unverified?).and_return true
    allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
  end

  shared_examples_for "display_heading" do
    before :each do
      render file: 'insured/families/personal.html.erb'
    end

    it "should display the title" do
      expect(rendered).to have_selector('h1', text: "Manage Family")
    end

    it "should display notice of action title " do
      expect(rendered).to have_selector('p', text: "#{l10n('insured.contact_preference')}")
    end
  end

  context "for employee role", dbclean: :after_each do
    before :each do
      assign(:employee_role, employee_role)
      allow(person).to receive(:employee_roles).and_return([employee_role])
      allow(view).to receive(:verification_needed?).and_return true
      allow(view).to receive(:documents_uploaded).and_return true
      render file: 'insured/families/personal.html.erb'
    end

    let(:person) {FactoryBot.create(:person, :with_family)}
    let(:employee_role) {FactoryBot.create(:employee_role, census_employee_id: census_employee.id)}
    let(:census_employee) {FactoryBot.create(:census_employee)}
    let(:current_user) {FactoryBot.create(:user, person: person)}

    it 'should renders home address fields' do
      expect(response).to render_template('shared/_home_address_fields')
    end

    it_should_behave_like 'display_heading'

    it 'should display contact method dropdown' do
      expect(rendered).to have_select('person[employee_roles_attributes][0][contact_method]', :selected => 'Only electronic communications')
    end

    it 'should display language preference dropdown' do
      expect(rendered).to have_select('person[employee_roles_attributes][0][language_preference]', :selected => 'English')
    end
  end

  if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
    context "for consumer role" do
      before :each do
        render file: 'insured/families/personal.html.erb'
      end

      let(:person) {FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
      let(:current_user) { FactoryBot.create(:user, person: person) }

      it "should renders home address fields and consumer fields" do
        expect(response).to render_template("shared/_consumer_fields")
        expect(response).to render_template("shared/_consumer_home_address_fields")
      end
      it_should_behave_like "display_heading"

      it "should display contact method dropdown " do
        expect(rendered).to have_select("person[consumer_role_attributes][contact_method]", :selected => "Both electronic and paper communications")
      end

      it "should display language preference dropdown " do
        expect(rendered).to have_select("person[consumer_role_attributes][language_preference]", :selected => "English")
      end
    end
  end
end
