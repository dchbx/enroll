require 'rails_helper'

RSpec.describe EnrollmentPeriod::SpecialEnrollment, :type => :model do

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
  let(:ivl_qle)       { QualifyingLifeEventKind.create(
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
                              post_event_sep_in_days: 30,
                              is_self_attested: true
                            )
                          }
  let(:qle_on)         { Date.current }

  let(:valid_params){
    {
      family: family,
      qualifying_life_event_kind: ivl_qle,
      qle_on: qle_on,
    }
  }

  context "a new instance" do
    context "with no family" do
      let(:params) {valid_params.except(:family)}

      it "should be invalid" do
        expect{EnrollmentPeriod::SpecialEnrollment.create(**params)}.to raise_error(Mongoid::Errors::NoParent)
      end
    end

    context "with no qualifying_life_event_kind" do
      let(:params) {valid_params.except(:qualifying_life_event_kind)}

      it "should be invalid" do
        expect(EnrollmentPeriod::SpecialEnrollment.create(**params).errors[:qualifying_life_event_kind_id].any?).to be_truthy
      end
    end

    context "with no qle_on" do
      let(:params) {valid_params.except(:qle_on)}

      it "should be invalid" do
        expect(EnrollmentPeriod::SpecialEnrollment.create(**params).errors[:qle_on].any?).to be_truthy
      end
    end

    context "with all valid arguments" do
      let(:params) { valid_params }
      let(:special_enrollment_period) { EnrollmentPeriod::SpecialEnrollment.new(**params) }

      # it "should save" do
      #   expect(special_enrollment_period.save).to be_truthy
      # end

    #   context "and it is saved" do
    #     let!(:saved_sep) do
    #       sep = special_enrollment_period
    #       sep.save
    #       sep
    #     end

    #     it "and should be findable" do
    #       expect(EnrollmentPeriod::SpecialEnrollment.find(saved_sep._id).id).to eq saved_sep.id
    #     end
    #   end
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

    context "and this is retro QLE that has lapsed" do
      let(:lapsed_qle_on_date)  { (TimeKeeper.date_of_record.beginning_of_month + 16.days) - 1.year }
      let(:qle_start_on_date)   { lapsed_qle_on_date }
      let(:qle_end_on_date)     { lapsed_qle_on_date + ivl_qle_sep.qualifying_life_event_kind.post_event_sep_in_days }

      before do
        ivl_qle_sep.qle_on = lapsed_qle_on_date
      end

      # it "should have a start date" do
      #   expect(ivl_qle_sep.start_on).to eq qle_start_on_date
      # end

      # it "should have an end date" do
      #   expect(ivl_qle_sep.end_on).to eq qle_end_on_date
      # end

      context "and 'effective on kind' is not set" do
        it "effective date should not be set" do
          expect(ivl_qle_sep.effective_on).to be_nil
        end
      end

      context "and 'effective on kind' is 'date of event'" do
        before { ivl_qle_sep.effective_on_kind = "date_of_event" }

        it "the effective date and QLE date should be the same" do
          expect(ivl_qle_sep.effective_on).to eq lapsed_qle_on_date
        end
      end

      context "and 'effective on kind' is 'fixed first of next month'" do
        let(:first_of_next_month_date)  { lapsed_qle_on_date.end_of_month + 1.day }
        before { ivl_qle_sep.effective_on_kind = "fixed_first_of_next_month" }

        it "the effective date should be first of month immediately following QLE date" do
          expect(ivl_qle_sep.effective_on).to eq first_of_next_month_date
        end
      end

      context "and 'effective on kind' is 'first of next month'" do
        let(:first_of_next_month_date)  { qle_end_on_date.end_of_month + 1.day }
        before { ivl_qle_sep.effective_on_kind = "first_of_next_month" }

        it "the effective date should be first of month immediately following last day of SEP date" do
          expect(ivl_qle_sep.effective_on).to eq first_of_next_month_date
        end
      end

      context "and 'effective on kind' is 'first of month'" do
        let(:expired_date)  { ivl_qle_sep.end_on.next_month.end_of_month + 1.day }
        before { ivl_qle_sep.effective_on_kind = "first_of_month" }

        # it "the effective date should be first of month immediately following QLE date" do
        #   expect(ivl_qle_sep.effective_on).to eq expired_date
        # end
      end
    end

    context "and this QLE date is reported on timely basis" do
      let(:today)               { TimeKeeper.date_of_record }
      # Ensure date is past 15th of the month
      let(:qle_on_date)         { today.day <= HbxProfile::IndividualEnrollmentDueDayOfMonth ? today.beginning_of_month - 1.day : today }
      let(:qle_start_on_date)   { lapsed_qle_on_date }
      let(:qle_end_on_date)     { lapsed_qle_on_date + ivl_qle_sep.qualifying_life_event_kind.post_event_sep_in_days }

      # it "Special Enrollment Period should be active" do
      #   expect(ivl_qle_sep.is_active?).to be_truthy
      # end

      context "and 'effective on kind' is 'first of month' and date is IndividualEnrollmentDueDayOfMonth of month or later" do
        let(:fifteenth_of_month_rule_date)  { qle_on_date.next_month.end_of_month + 1.day }
        before do
          TimeKeeper.set_date_of_record_unprotected!(Date.new(2015,10,20))
          ivl_qle_sep.qle_on = qle_on_date
          ivl_qle_sep.effective_on_kind = "first_of_month"
        end
        after do
          TimeKeeper.set_date_of_record_unprotected!(Date.today)
        end

        it "the effective date is first of next month following QLE date" do
          expect(ivl_qle_sep.effective_on).to eq fifteenth_of_month_rule_date
        end
      end

      context "and 'effective on kind' is 'first of month' and date is 15th of month or ealier" do
        let(:qle_on_date)                   { Date.new(today.year, today.month, 1) }
        let(:fifteenth_of_month_rule_date)  { qle_on_date.end_of_month + 1.day }
        before do 
          TimeKeeper.set_date_of_record_unprotected!(Date.new(2015,10,5))
          ivl_qle_sep.effective_on_kind = "first_of_month"
          ivl_qle_sep.qle_on = qle_on_date
        end
        after do
          TimeKeeper.set_date_of_record_unprotected!(Date.today)
        end

        it "the effective date is first of next month following QLE date" do
          # expect(ivl_qle_sep.effective_on).to eq fifteenth_of_month_rule_date
        end
      end

      context "and 'effective on kind' is 'first of next month'" do
        let(:first_of_next_month_date)  { today.end_of_month + 1.day }
        before do
          ivl_qle_sep.effective_on_kind = "first_of_next_month"
          ivl_qle_sep.qle_on = qle_on_date
        end

        it "the effective date should be first of month immediately following current date" do
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
    let(:sep_effective_date) { EnrollmentPeriod::SpecialEnrollment.new(qualifying_life_event_kind: qle_effective_date, effective_on_kind: 'date_of_event', qle_on: event_date) }
    let(:sep_first_of_month) { EnrollmentPeriod::SpecialEnrollment.new(qualifying_life_event_kind: qle_first_of_month, effective_on_kind: 'first_of_month', qle_on: event_date) }
    let(:sep_expired) { EnrollmentPeriod::SpecialEnrollment.new(qualifying_life_event_kind: qle_first_of_month, qle_on: expired_event_date) }
    let(:sep) { EnrollmentPeriod::SpecialEnrollment.new }
    let(:qle) { FactoryGirl.create(:qualifying_life_event_kind) }

    context "SHOP QLE and event date are specified" do
      it "should set start_on date to date of event" do
        expect(sep_effective_date.start_on).to eq event_date
      end

      context "and qle is effective on date of event" do
        it "should set effective date to date of event" do
          expect(sep_effective_date.effective_on).to eq event_date
        end
      end

      context "and QLE is effective on first of following month" do
        it "should set effective date to date of event" do
          # expect(sep_first_of_month.effective_on).to eq first_of_following_month
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

        it "should set effective date to date of event" do
          sep.qualifying_life_event_kind = qle
          sep.effective_on_kind = "first_of_next_month"
          sep.qle_on = TimeKeeper.date_of_record + 40.days
          expect(sep.effective_on).to eq ((TimeKeeper.date_of_record+40.days).end_of_month + 1.day)
        end

        it "should set effective date to current date" do
          sep.qualifying_life_event_kind = qle
          sep.effective_on_kind = "first_of_next_month"
          sep.qle_on = TimeKeeper.date_of_record - 4.days
          expect(sep.effective_on).to eq (TimeKeeper.date_of_record.end_of_month + 1.day)
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

      context "for first_of_month" do
        before :each do
          sep.qualifying_life_event_kind = qle
          sep.effective_on_kind = "first_of_month"
        end

        context "current date is 15th of month or earlier" do
          before {TimeKeeper.set_date_of_record_unprotected!(Date.new(2015,10,5))}
          after {TimeKeeper.set_date_of_record_unprotected!(Date.today)}
            
          it "should the first of month following qle date" do
            event_date = TimeKeeper.date_of_record + 10.days
            sep.qle_on = event_date
            expect(sep.effective_on).to eq event_date.end_of_month + 1.day
          end

          it "should the first of month following current date" do
            event_date = TimeKeeper.date_of_record - 8.days
            sep.qle_on = event_date
            expect(sep.effective_on).to eq TimeKeeper.date_of_record.end_of_month + 1.day
          end
        end

        context "current date is 16th of month or later" do
          before {TimeKeeper.set_date_of_record_unprotected!(Date.new(2015,10,25))}
          after {TimeKeeper.set_date_of_record_unprotected!(Date.today)}
            
          it "should the first of next month following qle date" do
            event_date = TimeKeeper.date_of_record + 10.days
            sep.qle_on = event_date
            expect(sep.effective_on).to eq event_date.next_month.end_of_month + 1.day
          end
            
          it "should the first of next month following current date" do
            event_date = TimeKeeper.date_of_record - 28.days
            sep.qle_on = event_date
            expect(sep.effective_on).to eq TimeKeeper.date_of_record.next_month.end_of_month + 1.day
          end
        end
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
end
