require 'rails_helper'

module SponsoredBenefits
  RSpec.describe BenefitApplications::EmployerProfileBuilder, type: :model do
    let(:effective_period_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day + 1.month }
    let(:effective_period_end_on)   { effective_period_start_on + 1.year - 1.day }
    let(:effective_period)          { effective_period_start_on..effective_period_end_on }

    let(:open_enrollment_period_start_on) { effective_period_start_on.prev_month }
    let(:open_enrollment_period_end_on)   { open_enrollment_period_start_on + 9.days }
    let(:open_enrollment_period)          { open_enrollment_period_start_on..open_enrollment_period_end_on }

    let(:params) do
      {
        effective_period: effective_period,
        open_enrollment_period: open_enrollment_period,
      }
    end

    context "add_plan_year" do

      let(:employer_profile)          { EmployerProfile.new }
      let(:benefit_application)       { SponsoredBenefits::BenefitApplications::BenefitApplication.new(params) }
      let(:benefit_sponsorship)       { SponsoredBenefits::BenefitSponsorships::BenefitSponsorship.new(
        benefit_market: "aca_shop_cca",
        enrollment_frequency: "rolling_month"
      )}

      let(:address)  { Address.new(kind: "primary", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002", county: "County") }
      let(:phone  )  { Phone.new(kind: "main", area_code: "202", number: "555-9999") }
      let(:office_location) { OfficeLocation.new(
          is_primary: true,
          address: address,
          phone: phone
        )
      }

      let(:plan_design_organization)  { SponsoredBenefits::Organizations::PlanDesignOrganization.new(legal_name: "xyz llc", office_locations: [office_location]) }
      let(:plan_design_proposal)      { SponsoredBenefits::Organizations::PlanDesignProposal.new(title: "New Proposal") }
      let(:profile) {SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile.new}

      before(:each) do
        plan_design_organization.plan_design_proposals << [plan_design_proposal]
        plan_design_proposal.profile = profile
        profile.benefit_sponsorships = [benefit_sponsorship]
        benefit_sponsorship.benefit_applications = [benefit_application]
        benefit_application.benefit_groups.build
        plan_design_organization.save
      end

      it "should successfully add plan year to employer profile with published quote" do
        allow(employer_profile).to receive(:active_plan_year).and_return(nil)
        plan_design_proposal.publish!
        builder = SponsoredBenefits::BenefitApplications::EmployerProfileBuilder.new(plan_design_proposal, employer_profile)
        expect(employer_profile.plan_years.present?).to eq false
        expect(builder.add_plan_year).to eq true
        expect(employer_profile.plan_years.present?).to eq true
      end
    end
  end
end
