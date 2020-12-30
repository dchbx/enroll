require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe "employee_enrollments.html.slim.rb", :type => :view, dbclean: :after_each  do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:current_effective_date)  { Date.new(TimeKeeper.date_of_record.year, 2, 1) }
  let(:census_employees) { FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package) }

  describe "employer profile home page" do

    before :each do
      assign(:current_plan_year, initial_application)
      allow(initial_application).to receive(:employee_participation_ratio_minimum).and_return(Settings.aca.shop_market.employee_participation_ratio_minimum)
      render partial: "ui-components/v1/cards/employee_enrollments"
    end

    it "should return proper message in tooltip when there is benefit application" do
      expect(rendered).to match /At least #{(Settings.aca.shop_market.employee_participation_ratio_minimum * 100).to_i} percent of your eligible employees must enroll or waive coverage during the open enrollment period in order to establish your Health Benefits Program. One of your enrollees must also be a non-owner/
      expect(rendered).to match /Employee Enrollments and Waivers/
    end
  end
end

