require 'rails_helper'

RSpec.describe SpecialEnrollmentPeriod, :type => :model do

  let(:family)        { FactoryGirl.create(:family, :with_primary_family_member) }
  let(:shop_qle)      { QualifyingLifeEventKind.create(
                              title: "Entered into a legal domestic partnership",
                              action_kind: "add_benefit",
                              reason: "domestic_partnership",
                              edi_code: "33-ENTERING DOMESTIC PARTNERSHIP",
                              market_kind: "shop",
                              effective_on_kinds: ["first_of_month"],
                              pre_event_sep_in_days: 0,
                              post_event_sep_in_days: 30,
                              is_self_attested: true,
                              ordinal_position: 20,
                              event_kind_label: 'Date of domestic partnership',
                              tool_tip: "Enroll or add a family member due to a new domestic partnership"
                            )
                          }
  let(:retro_ivl_qle) { QualifyingLifeEventKind.create(
                              title: "Had a baby",
                              tool_tip: "Household adds a member due to birth",
                              action_kind: "add_member",
                              market_kind: "individual",
                              event_kind_label: "Date of birth",
                              reason: "birth",
                              edi_code: "02-BIRTH",
                              ordinal_position: 10,
                              effective_on_kinds: ["date_of_event", "fixed_first_of_next_month"],
                              pre_event_sep_in_days: 0,
                              post_event_sep_in_days: 60,
                              is_self_attested: true
                            )
                          }

  let(:ivl_qle)       { QualifyingLifeEventKind.create(
                              title: "Lost or will soon lose other health insurance ",
                              tool_tip: "Someone in the household is losing other health insurance involuntarily",
                              action_kind: "add_benefit",
                              event_kind_label: "Coverage end date",
                              market_kind: "individual",
                              ordinal_position: 50,
                              reason: "lost_access_to_mec",
                              edi_code: "33-LOST ACCESS TO MEC",
                              effective_on_kinds: ["first_of_next_month"],
                              pre_event_sep_in_days: 60,
                              post_event_sep_in_days: 60, # "60 days before loss of coverage and 60 days after",
                              is_self_attested: true
                            )
                          }

  let(:qle_on)         { Date.current }

  let(:valid_params){
    {
      family: family,
      qualifying_life_event_kind: ivl_qle,
      effective_on_kind: "first_of_next_month",
      qle_on: qle_on,
    }
  }

  context "a new instance" do
    context "with no family" do
      let(:params) {valid_params.except(:family)}

      it "should raise an error" do
        expect{SpecialEnrollmentPeriod.create(**params)}.to raise_error(Mongoid::Errors::NoParent)
      end
    end

    context "with no qualifying_life_event_kind" do
      let(:params) {valid_params.except(:qualifying_life_event_kind)}

      it "should be invalid" do
        expect(SpecialEnrollmentPeriod.create(**params).errors[:qualifying_life_event_kind_id].any?).to be_truthy
      end
    end

    context "with no qle_on" do
      let(:params) {valid_params.except(:qle_on)}

      it "should be invalid" do
        expect(SpecialEnrollmentPeriod.create(**params).errors[:qle_on].any?).to be_truthy
      end
    end

    context "with all valid arguments" do
      let(:params) { valid_params }
      let(:special_enrollment_period) { SpecialEnrollmentPeriod.new(**params) }

      it "should save" do
        expect(special_enrollment_period.save).to be_truthy
      end

      context "and it is saved" do
        let!(:saved_sep) do
          sep = special_enrollment_period
          sep.save
          sep
        end

        it "and should be findable" do
          expect(SpecialEnrollmentPeriod.find(saved_sep._id).id).to eq saved_sep.id
        end
      end
    end
  end


  context "for an Individual Qualifying Life Event" do
    let(:ivl_qle_sep) { family.special_enrollment_periods.build(qualifying_life_event_kind: ivl_qle) }

    it "qle market kind should be individual" do
      expect(ivl_qle_sep.qualifying_life_event_kind.market_kind).to eq "individual"
    end

    it "sep title should be set to QLE kind title" do
      expect(ivl_qle_sep.title).to eq ivl_qle.title
    end

    it "effective date should not be set" do
      expect(ivl_qle_sep.effective_on).to be_nil
    end

    after :all do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end

    context "and QLE is reported before end of SEP" do
      let(:today)                           { TimeKeeper.date_of_record }
      let(:monthly_enrollment_deadline)     { today.beginning_of_month + Setting.individual_market_monthly_enrollment_due_on.days - 1.day }

      let(:qle_on_date)                     { today.beginning_of_month }

      let(:pre_enrollment_deadline_date)    { monthly_enrollment_deadline }
      let(:post_enrollment_deadline_date)   { monthly_enrollment_deadline  + 1.day }

      let(:next_month_date)                 { today.end_of_month + 1.day }
      let(:month_after_next_date)           { next_month_date.next_month }
      let(:ivl_qle_sep) { family.special_enrollment_periods.build(qualifying_life_event_kind: ivl_qle, qle_on: qle_on_date) }


      context "and 'effective on kind' is 'first of month' and date reported is before the deadline for current month" do
        let(:reporting_date)  { pre_enrollment_deadline_date }

        before do
          TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          ivl_qle_sep.effective_on_kind = "first_of_month"
        end

        it "the effective date should be first of month immediately following current date" do
          expect(ivl_qle_sep.effective_on).to eq next_month_date
        end
      end

      context "and 'effective on kind' is 'first of month' and date reported is after the monthly deadline" do
        let(:reporting_date)  { post_enrollment_deadline_date }

        before do
          TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          ivl_qle_sep.effective_on_kind = "first_of_month"
        end

        it "the effective date is first of next month following QLE date" do
          expect(ivl_qle_sep.effective_on).to eq month_after_next_date
        end
      end

      context "and 'effective on kind' is 'first of next month' and date reported is before the deadline for current month" do
        let(:reporting_date)  { pre_enrollment_deadline_date }

        before do
          TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          ivl_qle_sep.effective_on_kind = "first_of_next_month"
        end

        it "the effective date should be first of month following current date" do
          expect(ivl_qle_sep.effective_on).to eq next_month_date
        end
      end

      context "and 'effective on kind' is 'first of next month' and date reported is after the monthly deadline" do
        let(:reporting_date)  { post_enrollment_deadline_date }

        before do
          TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          ivl_qle_sep.effective_on_kind = "first_of_next_month"
        end

        it "the effective date should be first of month following current date" do
          expect(ivl_qle_sep.effective_on).to eq next_month_date
        end
      end

      it "and 'effective on kind' is 'first of next month' and date reported is after the monthly deadline and date of event is beginning of month" do
        ivl_qle_sep.effective_on_kind = "first_of_next_month"
        ivl_qle_sep.qle_on = TimeKeeper.date_of_record.end_of_month + 1.days
        expect(ivl_qle_sep.effective_on).to eq ((TimeKeeper.date_of_record.end_of_month + 1.days).end_of_month + 1.days)
      end
    end

    context "and QLE is reported after the that has lapsed" do
      let(:lapsed_qle_on_date)  { (TimeKeeper.date_of_record.beginning_of_month + 16.days) - 1.year }

      # let(:qle_start_on_date)   { lapsed_qle_on_date }
      # let(:qle_end_on_date)     { lapsed_qle_on_date + ivl_qle_sep.qualifying_life_event_kind.post_event_sep_in_days }

      let(:ivl_qle_sep) { family.special_enrollment_periods.build(qualifying_life_event_kind: ivl_qle, qle_on: lapsed_qle_on_date) }
      let(:reporting_date)        { Date.current }
      let(:lapsed_effective_date) { ivl_qle_sep.end_on.end_of_month + 1.day }

      before do
        TimeKeeper.set_date_of_record_unprotected!(reporting_date)
        ivl_qle_sep.effective_on_kind = "first_of_next_month"
      end

      after :all do
        TimeKeeper.set_date_of_record_unprotected!(Date.today)
      end

      it "the effective date should be in the past: first of month following the lapsed date" do
        expect(ivl_qle_sep.effective_on).to eq lapsed_effective_date
      end

      it "Special Enrollment Period should not be active" do
        expect(ivl_qle_sep.is_active?).to be_falsey
      end

      context "and 'effective on kind' is 'fixed first of next month'" do
        let(:first_of_next_month_date)  { lapsed_qle_on_date.end_of_month + 1.day }
        before { ivl_qle_sep.effective_on_kind = "fixed_first_of_next_month" }

        it "the effective date should be first of month immediately following QLE date" do
          expect(ivl_qle_sep.effective_on).to eq first_of_next_month_date
        end
      end
    end

  end

  context "Family experiences IVL Qualifying Life Event" do

  end


  let(:event_date) { TimeKeeper.date_of_record }
  let(:expired_event_date) { TimeKeeper.date_of_record - 1.year }
  let(:first_of_following_month) { TimeKeeper.date_of_record.end_of_month + 1 }
  let(:qle_effective_date) { FactoryGirl.create(:qualifying_life_event_kind, :effective_on_event_date) }
  let(:qle_first_of_month) { FactoryGirl.create(:qualifying_life_event_kind, :effective_on_first_of_month) }

  describe "it should set SHOP Special Enrollment Period dates based on QLE kind" do
    let(:sep_effective_date) { SpecialEnrollmentPeriod.new(qualifying_life_event_kind: qle_effective_date, effective_on_kind: 'date_of_event', qle_on: event_date) }
    let(:sep_first_of_month) { SpecialEnrollmentPeriod.new(qualifying_life_event_kind: qle_first_of_month, effective_on_kind: 'first_of_month', qle_on: event_date) }
    let(:sep_expired) { SpecialEnrollmentPeriod.new(qualifying_life_event_kind: qle_first_of_month, qle_on: expired_event_date) }
    let(:sep) { SpecialEnrollmentPeriod.new }
    let(:qle) { FactoryGirl.create(:qualifying_life_event_kind, market_kind: 'shop') }

    context "SHOP QLE and event date are specified" do
      it "should set start_on date to date of event" do
        expect(sep_effective_date.start_on).to eq event_date
      end

      context "and qle is effective on date of event" do
        it "should set effective date to date of event" do
          expect(sep_effective_date.effective_on).to eq event_date
        end
      end

      context "and qle is first_of_next_month" do
        it "when is_dependent_loss_of_coverage" do
          sep.effective_on_kind = "first_of_next_month"
          sep.qualifying_life_event_kind = qle
          allow(qle).to receive(:is_dependent_loss_of_coverage?).and_return true
          allow(qle).to receive(:employee_gaining_medicare).and_return (TimeKeeper.date_of_record - 1.day)
          sep.qle_on = TimeKeeper.date_of_record + 40.days
          expect(sep.effective_on).to eq (TimeKeeper.date_of_record - 1.day)
        end

        context "when is_moved_to_dc" do
          it "when current_date > qle on" do
            sep.effective_on_kind = "first_of_next_month"
            sep.qualifying_life_event_kind = qle
            allow(qle).to receive(:is_moved_to_dc?).and_return true
            sep.qle_on = TimeKeeper.date_of_record - 40.days
            expect(sep.effective_on).to eq (TimeKeeper.date_of_record.end_of_month + 1.day)
          end

          context "when current_date < qle on" do
            it "qle on is not beginning_of_month" do
              sep.effective_on_kind = "first_of_next_month"
              sep.qualifying_life_event_kind = qle
              allow(qle).to receive(:is_moved_to_dc?).and_return true
              sep.qle_on = TimeKeeper.date_of_record.end_of_month + 2.days
              expect(sep.effective_on).to eq ((TimeKeeper.date_of_record.end_of_month+2.days).end_of_month + 1.day)
            end

            it "qle on is beginning_of_month" do
              sep.effective_on_kind = "first_of_next_month"
              sep.qualifying_life_event_kind = qle
              allow(qle).to receive(:is_moved_to_dc?).and_return true
              sep.qle_on = TimeKeeper.date_of_record.end_of_month + 1.days
              expect(sep.effective_on).to eq (TimeKeeper.date_of_record.end_of_month+1.days)
            end
          end
        end

        it "should set effective date to date of event when date of event is not beginning of month" do
          sep.qualifying_life_event_kind = qle
          sep.effective_on_kind = "first_of_next_month"
          sep.qle_on = TimeKeeper.date_of_record + 40.days
          expected_effective_on = (TimeKeeper.date_of_record+40.days).end_of_month + 1.day
          expected_effective_on = sep.qle_on if sep.qle_on == sep.qle_on.at_beginning_of_month
          expect(sep.effective_on).to eq (expected_effective_on)
        end

        it "should set effective date to date of event when date of event is not beginning of month" do
          sep.qualifying_life_event_kind = qle
          sep.effective_on_kind = "first_of_next_month"
          qle_on = TimeKeeper.date_of_record.end_of_month - 10.days
          sep.qle_on = qle_on
          expect(sep.effective_on).to eq (qle_on.end_of_month + 1.day)
        end

        it "should set effective date to date of event when date of event is beginning of month" do
          sep.qualifying_life_event_kind = qle
          sep.effective_on_kind = "first_of_next_month"
          sep.qle_on = TimeKeeper.date_of_record.beginning_of_month
          expect(sep.effective_on).to eq TimeKeeper.date_of_record.beginning_of_month
        end
      end

      it "and qle is fixed_first_of_next_month" do
        sep.qualifying_life_event_kind = qle
        sep.effective_on_kind = "fixed_first_of_next_month"
        sep.qle_on = event_date
        expect(sep.effective_on).to eq first_of_following_month
      end

      it "and qle is exact_date" do
        sep.qualifying_life_event_kind = qle
        sep.effective_on_kind = "exact_date"
        sep.qle_on = event_date
        expect(sep.effective_on).to eq event_date
      end

    end

    context "SEP is active as of this date" do
      it "#is_active? should return true" do
        expect(sep_first_of_month.is_active?).to be_truthy
      end
    end

    context "SEP occured in the past, and is no longer active" do

      it "#is_active? should return false" do
        expect(sep_expired.is_active?).to be_falsey
      end
    end
  end

  context "#is_shop?" do
    let(:ivl_qle_sep) { family.special_enrollment_periods.build(qualifying_life_event_kind: ivl_qle) }
    let(:shop_qle_sep) { family.special_enrollment_periods.build(qualifying_life_event_kind: shop_qle) }

    it "should return true when shop qle" do
      expect(shop_qle_sep.is_shop?).to be_truthy
    end

    it "should return false when ivl qle" do
      expect(ivl_qle_sep.is_shop?).to be_falsey
    end
  end


  context "is reporting a qle before the employer plan start_date" do
    let(:plan_year_start_on) { Date.new(TimeKeeper.date_of_record.year, 06, 01) }
    let(:sep_effective_on) { Date.new(TimeKeeper.date_of_record.year, 04, 01) }
    let!(:published_plan_year) { FactoryGirl.create(:plan_year, start_on: plan_year_start_on) }
    let(:census_employee) { FactoryGirl.create(:census_employee, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789', hired_on: Date.new(TimeKeeper.date_of_record.year, 04, 14)) }
    let(:shop_family)       { FactoryGirl.create(:family, :with_primary_family_member)  }

    let(:sep){
      sep = shop_family.special_enrollment_periods.new
      sep.effective_on_kind = 'first_of_month'
      sep.qualifying_life_event_kind= qle_first_of_month
      sep.qle_on= Date.new(TimeKeeper.date_of_record.year, 04, 14)
      sep
    }

    before do
      published_plan_year.update_attributes('aasm_state' => 'published')
      shop_family.primary_applicant.person.employee_roles.create(
        employer_profile: published_plan_year.employer_profile,
        hired_on: census_employee.hired_on,
        census_employee_id: census_employee.id
      )
    end

    it "should return a sep with an effective date that equals to employers plan year start-date when sep_effective_date  < plan_year_start_on" do
       expect(sep.effective_on).to eq published_plan_year.start_on
    end
  end

end
