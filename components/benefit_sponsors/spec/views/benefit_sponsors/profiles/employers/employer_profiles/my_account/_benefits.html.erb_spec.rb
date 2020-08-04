# frozen_string_literal: true

require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe "views/benefit_sponsors/profiles/employers/employer_profiles/my_account/_benefits.html.erb", :type => :view, dbclean: :after_each do

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:employer_profile) { abc_profile }
  let!(:benefit_application) { initial_application }
  let(:benefit_group) { current_benefit_package }
  let(:renewal_effective_date) { (TimeKeeper.date_of_record + 2.months).beginning_of_month }
  let(:census_employee1) { FactoryBot.create(:census_employee, employer_profile: employer_profile) }
  let(:user) { FactoryBot.create(:user) }

  context "Add Plan year display" do

    before :each do
      view.extend BenefitSponsors::Engine.routes.url_helpers
      view.extend BenefitSponsors::PermissionHelper
      view.extend BenefitSponsors::ApplicationHelper
      view.extend BenefitSponsors::Employers::EmployerHelper

      benefit_sponsorship.benefit_applications.flat_map(&:benefit_packages).each { |bp| bp.sponsored_benefits.delete_all }
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true, revert_application?: true, list_enrollments?: true))
      sign_in(user)
      assign(:employer_profile, employer_profile)
      assign(:benefit_sponsorship, benefit_sponsorship)
      assign(:benefit_applications, benefit_sponsorship.benefit_applications)
    end

    context "renewals" do

      let(:renewal_benefit_sponsor_catalog) do
        build(
          :benefit_markets_benefit_sponsor_catalog,
          effective_date: renewal_effective_date,
          effective_period: renewal_effective_date..renewal_effective_date.next_year.prev_day,
          open_enrollment_period: renewal_effective_date.prev_month..(renewal_effective_date - 15.days)
        )
      end
      let!(:renewal_application) do
        renewal_application = initial_application.renew(renewal_benefit_sponsor_catalog)
        renewal_application.save
        renewal_benefit_sponsor_catalog.save
        renewal_application
      end

      context "when an active and draft benefit applications are present" do

        it "should not display add plan year button" do
          render "benefit_sponsors/profiles/employers/employer_profiles/my_account/benefits.html.erb"
          expect(rendered).not_to have_selector("a", text: "Add Plan Year")
        end
      end

      context "when an active and canceled benefit applications are present" do

        before do
          renewal_application.cancel!
          renewal_application.reload
        end

        it "should display add plan year button" do
          render "benefit_sponsors/profiles/employers/employer_profiles/my_account/benefits.html.erb"
          expect(rendered).to have_selector("a", text: "Add Plan Year")
        end
      end

      context "when the most recent benefit application is in enrollment ineligible state" do

        before do
          renewal_application.update_attributes!(:aasm_state => :enrollment_ineligible)
          renewal_application.reload
        end

        it "should display add plan year button" do
          render "benefit_sponsors/profiles/employers/employer_profiles/my_account/benefits.html.erb"
          expect(rendered).to have_selector("a", text: "Add Plan Year")
        end
      end
    end

    context "initials" do

      it "should display add plan year button when draft application is present" do
        benefit_application.update_attributes!(aasm_state: :draft)
        render "benefit_sponsors/profiles/employers/employer_profiles/my_account/benefits.html.erb"
        expect(rendered).to have_selector("a", text: "Add Plan Year")
      end

      it "should display add plan year button when active application is present" do
        render "benefit_sponsors/profiles/employers/employer_profiles/my_account/benefits.html.erb"
        expect(rendered).not_to have_selector("a", text: "Add Plan Year")
      end
    end
  end
end
