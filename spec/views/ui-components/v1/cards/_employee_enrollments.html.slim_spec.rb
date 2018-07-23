require 'rails_helper'

RSpec.describe "employee_enrollments.html.slim.rb", :type => :view, dbclean: :after_each  do

  let(:start_on){ TimeKeeper.date_of_record.end_of_month + 1.day + 1.month }

  let(:benefit_application) {
    double("BenefitSponsors::BenefitApplications::BenefitApplication",
      start_on: start_on,
      end_on: start_on + 1.year - 1.day,
      open_enrollment_start_on: (start_on - 30).beginning_of_month,
      open_enrollment_end_on: (start_on - 30).beginning_of_month + Settings.aca.shop_market.open_enrollment.monthly_end_on.days - 1.day,
      employer_profile: employer_profile,
      eligible_to_enroll_count: 0,
      total_enrolled_count: 0,
      non_business_owner_enrolled: [double],
      covered_count: 0,
      waived_count: 0,
      additional_required_participants_count: 0

    )
  }

  let(:employer_profile){
    double("BenefitSponsors::Organizations::AcaShopCcaEmployerProfile",
      census_employees: census_employees
    )
  }

  let(:census_employees){ double("CensusEmployees") }

  describe "employer profile home page" do

    before :each do
      allow(census_employees).to receive(:active).and_return([census_employees])
      assign(:current_plan_year, benefit_application)
      render partial: "ui-components/v1/cards/employee_enrollments"
    end

    it "should return proper message in tooltip when there is benefit application" do
      expect(rendered).to match /At least 75 percent of your eligible employees must enroll or waive coverage during the open enrollment period in order to establish your Health Benefits Program. One of your enrollees must also be a non-owner/
      expect(rendered).to match /Employee Enrollments and Waivers/
    end

  end

end
