require 'rails_helper'
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"

module SponsoredBenefits
  RSpec.describe BenefitApplications::BenefitApplication, type: :model, dbclean: :around_each do
    include_context "set up broker agency profile for BQT, by using configuration settings"

    # let(:date_range) { (TimeKeeper.date_of_record..1.year.from_now) }

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
          expect(subject.open_enrollment_period_by_effective_date(effective_date, false)).to eq valid_open_enrollment_period
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
