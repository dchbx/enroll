require "rails_helper"

RSpec.describe "people/landing_pages/_personal.html.erb" do
  let(:person) { FactoryGirl.build(:person) }
  let(:person1) { FactoryGirl.build(:invalid_person) }
  let(:consumer_role) { FactoryGirl.build(:consumer_role) }
  context 'family is updateable' do
    before(:each) do
      allow(view).to receive(:policy_helper).and_return(double('FamilyPolicy', updateable?: true))
      assign(:person, person)
      person.addresses.build(kind: 'home')
      #controller.request.path_parameters[:employer_profile_id] = employer_profile.id
      #stub_template "shared/_reference_plans_list.html.erb" => ""
    end

    it "should show save button" do
      render :template => "people/landing_pages/_personal.html.erb"
      expect(rendered).to have_selector('button', text: 'Save')
      expect(rendered).not_to have_selector('.blocking', text: 'Save')
    end

    context "with consumer_role" do
      before :each do
        allow(person).to receive(:is_consumer_role_active?).and_return true
        allow(person).to receive(:consumer_role).and_return consumer_role
        render :template => "people/landing_pages/_personal.html.erb"
      end

      it "should have consumer_fields area" do
        expect(rendered).to have_selector('div#consumer_fields')
      end

      it "should display the is_applying_coverage field option" do
        expect(rendered).to match /Is #{person.first_name} applying for coverage?/
      end

      it "should display the affirmative message" do
        expect(rendered).not_to match /Your answer to this question does not apply to coverage offered by an employer./
      end

      it "should have no-dc-address-reasons area" do
        expect(rendered).to have_selector('div#address_info')
        expect(rendered).to match /homeless DC resident/
        expect(rendered).to match /living outside of DC temporarily and intend to return/
      end
    end

    context "without consumer_role" do
      before :each do
        allow(person).to receive(:is_consumer_role_active?).and_return false
        render :template => "people/landing_pages/_personal.html.erb"
      end

      it "should not have consumer_fields area" do
        expect(rendered).not_to have_selector('div#consumer_fields')
      end

      it "should not have no-dc-address-reasons area" do
        expect(rendered).not_to match /homeless DC resident/
        expect(rendered).not_to match /living outside of DC temporarily and intend to return/
      end

      it "should not display the is_applying_coverage field option" do
        expect(rendered).not_to match /Is this person applying for coverage?/
      end

      it "should display the affirmative message" do
        expect(rendered).not_to match /Your answer to this question does not apply to coverage offered by an employer./
      end

      it "should have home address fields" do
        expect(rendered).to have_selector('div#address_info')
        expect(rendered).to match /Home Address/
      end
    end
  end

  context 'create email when person has no home/work emails' do
    before(:each) do
      allow(view).to receive(:policy_helper).and_return(double('FamilyPolicy', updateable?: false))
      assign(:person, person1)
    end

    it "should show home email address" do
      person.emails.build(kind: 'home')
      render :template => "people/landing_pages/_personal.html.erb"
      expect(rendered).to have_selector('div#email_info')
      expect(rendered).to match /Home Email Address/
    end

    it "should show work email address" do
      person.emails.build(kind: 'work')
      render :template => "people/landing_pages/_personal.html.erb"
      expect(rendered).to have_selector('div#email_info')
      expect(rendered).to match /Work Email Address/
    end
  end

  context 'family is not updateable' do
    before(:each) do
      allow(view).to receive(:policy_helper).and_return(double('FamilyPolicy', updateable?: false))
      assign(:person, person)
      person.addresses.build(kind: 'home')
      #controller.request.path_parameters[:employer_profile_id] = employer_profile.id
      #stub_template "shared/_reference_plans_list.html.erb" => ""
    end

    it "should not show save button" do
      render :template => "people/landing_pages/_personal.html.erb"
      expect(rendered).to have_selector('.blocking', text: 'Save' )
    end
  end

  context "with both employee_role and consumer_role" do
    let(:person) {FactoryGirl.create(:person, :ssn => "123456789")}
    before :each do
      allow(view).to receive(:policy_helper).and_return(double('FamilyPolicy', updateable?: true))
      allow(person).to receive(:consumer_role).and_return consumer_role
      allow(person).to receive(:is_consumer_role_active?).and_return true
      allow(person).to receive(:has_active_employee_role?).and_return true
      assign(:person, person)
      render :template => "people/landing_pages/_personal.html.erb"
    end

    it "should display the affirmative message" do
      expect(rendered).to match /Your answer to this question does not apply to coverage offered by an employer./
    end
  end

  context "with employee_role" do
    let(:person) {FactoryGirl.create(:person)}
    before :each do
      allow(view).to receive(:policy_helper).and_return(double('FamilyPolicy', updateable?: true))
      allow(person).to receive(:has_active_employee_role?).and_return true
      assign(:person, person)
      render :template => "people/landing_pages/_personal.html.erb"
    end

    it "should display the affirmative message" do
      expect(rendered).not_to match /Your answer to this question does not apply to coverage offered by an employer./
    end
  end
end




