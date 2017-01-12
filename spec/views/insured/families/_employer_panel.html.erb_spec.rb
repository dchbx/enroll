require 'rails_helper'

RSpec.describe "insured/families/_employer_panel.html.erb" do
  let(:person) {FactoryGirl.build(:person)}
  let(:employee_role) {FactoryGirl.build(:employee_role)}
  let(:employer_profile) {FactoryGirl.build(:employer_profile)}

  before :each do
    assign(:person, person)
    assign(:employee_role, employee_role)
    allow(view).to receive(:is_under_open_enrollment?).and_return true
    allow(view).to receive(:policy_helper).and_return(double("EmployerProfilePolicy", updateable?: true))
    render "insured/families/employer_panel", employee_role: employee_role
  end

  context 'Person has a single employer/employee_role' do  
    let(:person) { FactoryGirl.create :person, :with_employee_role }

    before :each do
      render "insured/families/employer_panel", employee_role: person.employee_roles.first
    end

    it 'should have a single employee role' do
      expect(person.employee_roles.count).to eq(1)
    end

    it "should have carousel-qles area" do
      expect(rendered).to have_selector('div.alert-notice')
    end

    it "should have close link" do
      expect(rendered).to have_selector('a.close')
    end

    it "should have employer name" do
      expect(rendered).to have_selector('input')
      expect(rendered).to have_content("Congratulations on your new job at 
                                        #{person.employee_roles.first.employer_profile.legal_name}.")
    end
  end

  context 'Person has two employers/employee_roles' do  
    let(:person) { FactoryGirl.create :person, :with_employee_role, :with_employee_role }

    before :each do
      render "insured/families/employer_panel", employee_role: person.employee_roles.first
    end

    it 'should have two employee roles' do
      expect(person.employee_roles.count).to eq(2)
    end

    it 'should have two different employers' do
      expect(person.employee_roles.map(&:employer_profile_id).uniq.count).to eq(2)
    end

    it "should have carousel-qles area" do
      expect(rendered).to have_selector('div.alert-notice')
    end

    it "should have close link" do
      expect(rendered).to have_selector('a.close')
    end

    it "should have notices for both employers" do
      expect(rendered).to have_selector('input')
      expect(rendered).to have_content("Congratulations on your new job at 
                                        #{person.employee_roles[0].employer_profile.legal_name}.")
      expect(rendered).to have_content("Congratulations on your new job at 
                                        #{person.employee_roles[1].employer_profile.legal_name}.")
    end
  end
end
