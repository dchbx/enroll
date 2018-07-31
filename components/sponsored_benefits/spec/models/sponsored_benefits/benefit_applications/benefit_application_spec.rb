require 'rails_helper'

module SponsoredBenefits
  RSpec.describe BenefitApplications::BenefitApplication, type: :model, dbclean: :around_each do
    let(:subject) { BenefitApplications::BenefitApplication.new }

    # let(:date_range) { (Date.today..1.year.from_now) }

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


    context "with no arguments" do
      subject { described_class.new }

      it "should not be valid" do
        subject.validate
        expect(subject).to_not be_valid
      end
    end

    context "with no effective_period" do
      subject { described_class.new(params.except(:effective_period)) }

      it "should not be valid" do
        subject.validate
        expect(subject).to_not be_valid
      end
    end

    context "with no open enrollment period" do
      subject { described_class.new(params.except(:open_enrollment_period)) }

      it "should not be valid" do
        subject.validate
        expect(subject).to_not be_valid
      end
    end

    context "with all required arguments" do
      subject { described_class.new(params) }

      it "should be valid" do
        subject.validate
        expect(subject).to be_valid
      end
    end

    context "#to_benefit_sponsors_benefit_application" do
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
      let(:benefit_group)             { FactoryGirl.create :benefit_group }

      let(:benefit_market)      { site.benefit_markets.first }
      let(:current_effective_date)  { TimeKeeper.date_of_record }
      let!(:benefit_market_catalog) { create(:benefit_markets_benefit_market_catalog, :with_product_packages,
                                              benefit_market: benefit_market,
                                              title: "SHOP Benefits for #{current_effective_date.year}",
                                              application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year))
                                      }
      let!(:rating_area)   { FactoryGirl.create_default :benefit_markets_locations_rating_area }
      let!(:service_area)  { FactoryGirl.create_default :benefit_markets_locations_service_area }
      let(:site)                { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let(:benefit_sponsor_organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let(:sponsor_benefit_sponsorship) { benefit_sponsor_organization.employer_profile.add_benefit_sponsorship }

      let(:plan_design_organization)  { SponsoredBenefits::Organizations::PlanDesignOrganization.new(legal_name: "xyz llc", office_locations: [office_location]) }
      let(:plan_design_proposal)      { SponsoredBenefits::Organizations::PlanDesignProposal.new(title: "New Proposal") }
      let(:profile) {SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile.new}

      before(:each) do
        sponsor_benefit_sponsorship.rating_area = rating_area
        sponsor_benefit_sponsorship.service_areas = [service_area]
        sponsor_benefit_sponsorship.save
        plan_design_organization.plan_design_proposals << [plan_design_proposal]
        plan_design_proposal.profile = profile
        profile.benefit_sponsorships = [benefit_sponsorship]
        benefit_sponsorship.benefit_applications = [benefit_application]
        benefit_application.benefit_groups << benefit_group
        plan_design_organization.save
      end

      it "should instantiate a plan year object and must have correct values assigned" do
        ben_app = benefit_application.to_benefit_sponsors_benefit_application(benefit_sponsor_organization)
        expect(ben_app.class).to eq BenefitSponsors::BenefitApplications::BenefitApplication
        expect(ben_app.benefit_packages.present?).to eq true
        expect(ben_app.start_on).to eq benefit_application.effective_period.begin
        expect(ben_app.end_on).to eq benefit_application.effective_period.end
        expect(ben_app.open_enrollment_start_on).to eq benefit_application.open_enrollment_period.begin
        expect(ben_app.open_enrollment_end_on).to eq benefit_application.open_enrollment_period.end
      end
    end

    context "a BenefitApplication class" do
      let(:subject)             { BenefitApplications::BenefitApplication }
      let(:begin_day)  { Settings.aca.shop_market.open_enrollment.monthly_end_on -
                                  Settings.aca.shop_market.open_enrollment.minimum_length.adv_days }

      let(:grace_begin_day)     { Settings.aca.shop_market.open_enrollment.monthly_end_on -
                                  Settings.aca.shop_market.open_enrollment.minimum_length.days }

      def standard_begin_day
        (begin_day > 0) ? begin_day : 1
      end

      it "should return the day of month deadline for an open enrollment standard period to begin" do
        expect(subject.open_enrollment_minimum_begin_day_of_month).to eq standard_begin_day
      end

      it "should return the day of month deadline for an open enrollment grace period to begin" do
        expect(subject.open_enrollment_minimum_begin_day_of_month(true)).to eq grace_begin_day
      end

      # These specs are passing on Mass but failing when moved to DC. This is because the Settings file have different values for OE dates in the DC Env.
      # TODO: Fix during BQT code refactor.
      # context "and a calendar date is passed to effective period by date method" do
      #   let(:seed_date)                         { Date.new(2018,4,4) }
      #   let(:next_month_begin_on)               { seed_date.beginning_of_month + 1.month }
      #   let(:next_month_effective_period)       { next_month_begin_on..(next_month_begin_on + 1.year - 1.day) }
      #   let(:following_month_begin_on)          { seed_date.beginning_of_month + 2.months }
      #   let(:following_month_effective_period)  { following_month_begin_on..(following_month_begin_on + 1.year - 1.day) }

      #   let(:standard_period_last_day)          { subject.open_enrollment_minimum_begin_day_of_month }
      #   let(:standard_period_deadline_date)     { Date.new(seed_date.year, seed_date.month, standard_period_last_day) }
      #   let(:standard_period_pre_deadline_date) { standard_period_deadline_date - 1.day }

      #   let(:grace_period_last_day)             { subject.open_enrollment_minimum_begin_day_of_month(true) }
      #   let(:grace_period_deadline_date)        { Date.new(seed_date.year, seed_date.month, grace_period_last_day) }
      #   let(:grace_period_post_deadline_date)   { grace_period_deadline_date + 1.day }


      #   context "that is before standard period deadline" do
      #     it "should provide an effective (standard) period beginning the first of next month" do
      #       expect(subject.effective_period_by_date(standard_period_pre_deadline_date)).to eq next_month_effective_period
      #     end

      #     it "should provide an effective (grace) period beginning the first of next month" do
      #       expect(subject.effective_period_by_date(standard_period_pre_deadline_date, true)).to eq next_month_effective_period
      #     end
      #   end

      #   context "that is the same day as the standard period deadline" do
      #     it "should provide an effective (standard) period beginning the first of next month" do
      #       expect(subject.effective_period_by_date(standard_period_deadline_date)).to eq next_month_effective_period
      #     end

      #     it "should provide an effective (grace) period beginning the first of next month" do
      #       expect(subject.effective_period_by_date(standard_period_deadline_date, true)).to eq next_month_effective_period
      #     end
      #   end

      #   context "that is after the standard period, but before the grace period deadline" do
      #     it "should provide an effective (standard) period beginning the first of month following next month" do
      #       expect(subject.effective_period_by_date(grace_period_deadline_date)).to eq following_month_effective_period
      #     end

      #     it "should provide an effective (grace) period beginning the of first next month" do
      #       expect(subject.effective_period_by_date(grace_period_deadline_date, true)).to eq next_month_effective_period
      #     end
      #   end

      #   context "that is after both the standard and grace period deadlines" do
      #     it "should provide an effective (standard) period beginning the first of month following next month" do
      #       expect(subject.effective_period_by_date(grace_period_post_deadline_date)).to eq following_month_effective_period
      #     end

      #     it "should provide an effective (grace) period beginning the first of month following next month" do
      #       expect(subject.effective_period_by_date(grace_period_post_deadline_date, true)).to eq following_month_effective_period
      #     end
      #   end
      # end

      context "and an effective date is passed to open enrollment period by effective date method" do
        let(:effective_date)                  { (TimeKeeper.date_of_record + 3.months).beginning_of_month }
        let(:prior_month)                     { effective_date - 1.month }
        let(:valid_open_enrollment_begin_on)  { [(effective_date - Settings.aca.shop_market.open_enrollment.maximum_length.months.months), TimeKeeper.date_of_record].max}
        let(:valid_open_enrollment_end_on)    { ("#{effective_date.prev_month.year}-#{effective_date.prev_month.month}-#{Settings.aca.shop_market.open_enrollment.monthly_end_on}").to_date }
        let(:valid_open_enrollment_period)    { valid_open_enrollment_begin_on..valid_open_enrollment_end_on }

        it "should provide a valid open enrollment period for that effective date" do
          expect(subject.open_enrollment_period_by_effective_date(effective_date)).to eq valid_open_enrollment_period
        end
      end

      context "and an effective date is passed to enrollment timetable by effective date method" do
        let(:effective_date)                  { Date.new(2018,3,1) }

        let(:prior_month)                     { effective_date - 1.month }
        let(:late_open_enrollment_begin_day)  { Settings.aca.shop_market.open_enrollment.monthly_end_on -
                                                Settings.aca.shop_market.open_enrollment.minimum_length.adv_days }
        let(:open_enrollment_end_day)         { Settings.aca.shop_market.open_enrollment.monthly_end_on }
        let(:open_enrollment_end_on)          { Date.new(prior_month.year, prior_month.month, open_enrollment_end_day) }

        let(:late_open_enrollment_begin_on)   { Date.new(prior_month.year, prior_month.month, late_open_enrollment_begin_day) }
        let(:late_open_enrollment_period)     { late_open_enrollment_begin_on..open_enrollment_end_on }

        let(:valid_timetable)                 {
                                                {
                                                    effective_date:                 Date.new(2018,3,1),
                                                    effective_period:               Date.new(2018,3,1)..Date.new(2019,2,28),
                                                    open_enrollment_period:         Date.new(2018,1,1)..open_enrollment_end_on,
                                                    open_enrollment_period_minimum: late_open_enrollment_period,
                                                    binder_payment_due_on:          Date.new(2018,2,23)
                                                  }
                                               }
        # These specs are passing on Mass but failing when moved to DC. This is because the Settings file have different values for OE dates in the DC Env.
        # TODO: Fix during BQT code refactor.
        # it "should provide a valid an enrollment timetabe hash for that effective date" do
        #   expect(subject.enrollment_timetable_by_effective_date(effective_date)).to eq valid_timetable
        # end

        # it "timetable date values should be valid" do
        #   timetable = subject.enrollment_timetable_by_effective_date(effective_date)
        #   expect(subject.new(effective_period: timetable[:effective_period], open_enrollment_period: timetable[:open_enrollment_period])).to be_valid
        # end
      end

    end
  end
end
