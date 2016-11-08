require 'rails_helper'
RSpec.describe "_enrollment_report_widget.html.erb" do
  let(:employer_profile){FactoryGirl.create(:employer_profile)}
  let(:plan_year){FactoryGirl.create(:plan_year, employer_profile: employer_profile)}

  context "with active plan year billing date" do
    before :each do
      assign(:employer_profile, employer_profile)
      assign(:plan_year, plan_year)
      plan_year.update_attributes(aasm_state:'published')
      render 'employers/employer_profiles/enrollment_report_widget'
    end
  
      it "should display the following text" do
       expect(rendered).to have_selector('td', text: /Total Premium:/i)
       expect(rendered).to have_selector('td', text: /Employee Contributions:/i)
       expect(rendered).to have_selector('td', text: /Employer Contributions:/i)
      end
    end
    
  context "without active plan year" do
    let(:employer_profile) { FactoryGirl.build_stubbed(:employer_profile) }
    before :each do
      assign(:employer_profile, employer_profile)
      allow(employer_profile).to receive(:billing_plan_year).and_return([])
      render 'employers/employer_profiles/enrollment_report_widget'
    end

    it "should not display the widget" do
      expect(rendered).to_not have_selector('strong', text: /Enrollment Report/i)
    end
  end

end