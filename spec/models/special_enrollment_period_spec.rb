require 'rails_helper'

RSpec.describe SpecialEnrollmentPeriod, :type => :model, :dbclean => :after_each do

  describe "A new model instance", dbclean: :after_each do
    it { is_expected.to be_mongoid_document }
    it { is_expected.to have_fields(:qualifying_life_event_kind_id).of_type(BSON::ObjectId)}
    it { is_expected.to have_field(:qle_on).of_type(Date)}
    it { is_expected.to have_field(:is_valid).of_type(Mongoid::Boolean)}
    it { is_expected.to have_field(:effective_on_kind).of_type(String)}
    it { is_expected.to have_field(:effective_on).of_type(Date)}
    it { is_expected.to have_field(:submitted_at).of_type(DateTime)}
    it { is_expected.to have_field(:title).of_type(String)}
    it { is_expected.to have_field(:start_on).of_type(Date)}
    it { is_expected.to have_field(:end_on).of_type(Date)}
    it { is_expected.to have_field(:qle_answer).of_type(String)}
    it { is_expected.to have_field(:next_poss_effective_date).of_type(Date)}
    it { is_expected.to have_field(:option1_date).of_type(Date)}
    it { is_expected.to have_field(:option2_date).of_type(Date)}
    it { is_expected.to have_field(:option3_date).of_type(Date)}
    it { is_expected.to have_field(:csl_num).of_type(String)}
    it { is_expected.to have_field(:admin_flag).of_type(Mongoid::Boolean)}
    it { is_expected.to have_field(:optional_effective_on).of_type(Array).with_default_value_of([]) }
    it { is_expected.to have_field(:coverage_renewal_flag).of_type(Mongoid::Boolean).with_default_value_of(false) }
  end

  let(:family)        { FactoryBot.create(:family, :with_primary_family_member) }
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
                          is_visible: true,
                          ordinal_position: 20,
                          event_kind_label: 'Date of domestic partnership',
                          tool_tip: "Enroll or add a family member due to a new domestic partnership",
                          is_active: true
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
                          is_self_attested: true,
                          is_visible: true,
                          is_active: true
                        )
                        }

  let(:ivl_qle)       { QualifyingLifeEventKind.create(
                          title: "Married",
                          tool_tip: "Enroll or add a family member because of marriage",
                          action_kind: "add_benefit",
                          event_kind_label: "Date of married",
                          market_kind: "individual",
                          ordinal_position: 15,
                          reason: "marriage",
                          edi_code: "32-MARRIAGE",
                          effective_on_kinds: ["first_of_next_month"],
                          pre_event_sep_in_days: 0,
                          post_event_sep_in_days: 30,
                          is_self_attested: true,
                          is_visible: true,
                          is_active: true
                        )
                        }

  let(:ivl_lost_insurance_qle)       { QualifyingLifeEventKind.create(
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
                                         is_self_attested: true,
                                         is_visible: true,
                                         is_active: true
                                       )
                                       }

  let(:shop_lost_insurance_qle)       { QualifyingLifeEventKind.create(
                                          title: "Losing other health insurance",
                                          tool_tip: "Someone in the household is losing other health insurance involuntarily",
                                          action_kind: "add_benefit",
                                          event_kind_label: "Date of losing coverage",
                                          market_kind: "shop",
                                          ordinal_position: 35,
                                          reason: "lost_access_to_mec",
                                          edi_code: "33-LOST ACCESS TO MEC",
                                          effective_on_kinds: ["first_of_next_month"],
                                          pre_event_sep_in_days: 0,
                                          post_event_sep_in_days: 30, # "60 days before loss of coverage and 60 days after",
                                          is_self_attested: true,
                                          is_visible: true,
                                          is_active: true
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

  let(:fehb_qle) do
    QualifyingLifeEventKind.create(
      title: "Married",
      tool_tip: "Enroll or add a family member because of marriage",
      action_kind: "add_benefit",
      event_kind_label: "Date of married",
      market_kind: "fehb",
      ordinal_position: 15,
      reason: "marriage",
      edi_code: "32-MARRIAGE",
      effective_on_kinds: ["first_of_next_month"],
      pre_event_sep_in_days: 0,
      post_event_sep_in_days: 30,
      is_self_attested: true,
      is_visible: true,
      is_active: true
    )
  end

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

    context "with inactive qle" do
      let(:inactive_qle) { create(:qualifying_life_event_kind, title: "Married", market_kind: "shop", reason: "marriage", start_on: TimeKeeper.date_of_record.prev_month.beginning_of_month, end_on: TimeKeeper.date_of_record.prev_month.end_of_month) }
      let(:params) {valid_params.merge(qualifying_life_event_kind: inactive_qle, qle_on: TimeKeeper.date_of_record)}

      it "should raise inactive qle exception" do
        expect{SpecialEnrollmentPeriod.create(**params)}.to raise_error(StandardError, "Qualifying life event kind is expired")
      end
    end

    context "special enrollment peroid created when qle is active" do
      let(:active_qle) { create(:qualifying_life_event_kind, title: "Married", market_kind: "shop", reason: "marriage", start_on: TimeKeeper.date_of_record.prev_month.beginning_of_month, end_on: TimeKeeper.date_of_record.next_month.end_of_month) }
      let!(:sep) {FactoryBot.create(:special_enrollment_period, family: family, qualifying_life_event_kind: active_qle, market_kind: 'ivl', created_at: TimeKeeper.date_of_record - 2.day)}

      it "should not raise inactive qle exception" do
        active_qle.update_attributes(is_active: false, end_on: TimeKeeper.date_of_record - 1.day)
        valid_params = sep.attributes.except("effective_on", "submitted_at", "_id").merge(family: family, qualifying_life_event_kind: active_qle, title: "tttt")
        expect{SpecialEnrollmentPeriod.create(valid_params)}.not_to raise_error(StandardError, "Qualifying life event kind is expired")
      end
    end

    context "special enrollment peroid created when qle not active" do
      let(:active_qle) { create(:qualifying_life_event_kind, title: "Married", market_kind: "shop", reason: "marriage", start_on: TimeKeeper.date_of_record.prev_month.beginning_of_month, end_on: TimeKeeper.date_of_record.next_month.end_of_month) }
      let!(:sep) {FactoryBot.create(:special_enrollment_period, family: family, qualifying_life_event_kind: active_qle, market_kind: 'ivl', created_at: TimeKeeper.date_of_record)}

      it "should raise inactive qle exception" do
        active_qle.update_attributes(is_active: false, end_on: TimeKeeper.date_of_record - 1.day)
        valid_params = sep.attributes.except("effective_on", "submitted_at", "_id").merge(family: family, qualifying_life_event_kind: active_qle, title: "tttt")
        expect{SpecialEnrollmentPeriod.create(valid_params)}.to raise_error(StandardError, "Qualifying life event kind is expired")
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

    context "with invalid next_poss_effective_date" do
      let(:param_with_valid_next_poss_effective_date){
        {
          family: family,
          qualifying_life_event_kind: ivl_qle,
          effective_on_kind: "first_of_next_month",
          qle_on: qle_on,
          next_poss_effective_date: TimeKeeper.date_of_record + 2.years
        }
      }
      it "should be invalid" do
        expect(SpecialEnrollmentPeriod.create(**param_with_valid_next_poss_effective_date).errors[:next_poss_effective_date].any?).to be_falsey
      end
    end

    context "with invalid optional_effective_on" do
      let(:param_with_valid_optional_effective_on){
        {
          family: family,
          qualifying_life_event_kind: ivl_qle,
          effective_on_kind: "first_of_next_month",
          qle_on: qle_on,
          optional_effective_on: ["05/01/#{TimeKeeper.date_of_record.year + 1}", "05/03/#{TimeKeeper.date_of_record.year}"]
        }
      }
      it "should be invalid" do
        expect(SpecialEnrollmentPeriod.create(**param_with_valid_optional_effective_on).errors[:optional_effective_on].any?).to be_falsey
      end
    end

    context "with valid optional_effective_on" do
      let(:param_with_invalid_optional_effective_on){
        {
          family: family,
          qualifying_life_event_kind: ivl_qle,
          effective_on_kind: "first_of_next_month",
          qle_on: qle_on,
          optional_effective_on: ["07/03/#{TimeKeeper.date_of_record.year}", "09/07/#{TimeKeeper.date_of_record.year}"]
        }
      }
      it "should be valid" do
        expect(SpecialEnrollmentPeriod.create(**param_with_invalid_optional_effective_on).errors[:optional_effective_on].any?).to be_falsey
      end
    end
  end

  context ".next_poss_effective_date_within_range" do
    let(:shop_qle_sep) { FactoryBot.create(:special_enrollment_period, family: family) }
    let(:past_date) { TimeKeeper.date_of_record - 3.months }
    let(:shop_qle_sep_past_effective_on) { FactoryBot.build(:special_enrollment_period, family: family, next_poss_effective_date: past_date) }
    let(:ivl_qle_sep) { SpecialEnrollmentPeriod.create(**valid_params)}
    let(:min_date) { TimeKeeper.date_of_record - 1.month}
    let(:max_date) { TimeKeeper.date_of_record + 1.month}

    it "should receive nil when next_poss_effective_date is blank" do
      expect(shop_qle_sep.send(:next_poss_effective_date_within_range)).to eq nil
    end

    it "should return true if SEP is QLE event kind is IVL" do
      ivl_qle_sep.update_attributes(next_poss_effective_date: TimeKeeper.date_of_record)
      expect(ivl_qle_sep.send(:next_poss_effective_date_within_range)).to eq true
    end

    it "should return nil with SHOP SEP and next_poss_effective_date present" do
      # since module method invokes in class
      allow_any_instance_of(Family).to receive(:has_primary_active_employee?).and_return(true)
      allow_any_instance_of(SpecialEnrollmentPeriod).to receive(:sep_optional_date).with(ivl_qle_sep.family, "min", "shop").and_return(min_date)
      allow_any_instance_of(SpecialEnrollmentPeriod).to receive(:sep_optional_date).with(ivl_qle_sep.family, "max", "shop").and_return(max_date)
      shop_qle_sep.update_attributes(next_poss_effective_date: TimeKeeper.date_of_record)
      expect(shop_qle_sep.send(:next_poss_effective_date_within_range)).to eq nil
    end

    it "should not throw out of range error message" do
      # since module method invokes in class
      allow_any_instance_of(Family).to receive(:has_primary_active_employee?).and_return(true)
      allow_any_instance_of(SpecialEnrollmentPeriod).to receive(:sep_optional_date).with(ivl_qle_sep.family, "min", "shop").and_return(min_date)
      allow_any_instance_of(SpecialEnrollmentPeriod).to receive(:sep_optional_date).with(ivl_qle_sep.family, "max", "shop").and_return(max_date)
      expect(shop_qle_sep_past_effective_on.valid?).to eq false
      expect(shop_qle_sep_past_effective_on.errors.full_messages).to include "Next poss effective date out of range."
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
      let(:monthly_enrollment_deadline)     { today.beginning_of_month + EnrollRegistry[:special_enrollment_period].setting(:fifteenth_of_the_month).item.days - 1.day }

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

    context "and QLE is reported after the that has lapsed", dbclean: :after_each do
      let(:lapsed_qle_on_date)  { (TimeKeeper.date_of_record.beginning_of_month + 16.days) - 1.year }

      let(:ivl_qle_sep) { FactoryBot.create(:special_enrollment_period, family: family,
                                            qualifying_life_event_kind_id: ivl_qle.id, qle_on: lapsed_qle_on_date) }

      let(:ivl_lost_insurance_qle_sep) { FactoryBot.create(:special_enrollment_period, family: family,
                                                           qualifying_life_event_kind_id: ivl_lost_insurance_qle.id, qle_on: lapsed_qle_on_date) }

      let(:shop_lost_insurance_qle_sep) { FactoryBot.create(:special_enrollment_period, family: family,
                                                            qualifying_life_event_kind_id: shop_lost_insurance_qle.id, qle_on: lapsed_qle_on_date) }

      let(:reporting_date)        { Date.current }
      let(:lapsed_effective_date) { ivl_qle_sep.end_on.end_of_month + 1.day }

      before do
        TimeKeeper.set_date_of_record_unprotected!(reporting_date)
      end

      after :all do
        TimeKeeper.set_date_of_record_unprotected!(Date.today)
      end

      it "the effective date should be in the past: first of month following the lapsed date" do
        ivl_qle_sep.effective_on_kind = "first_of_next_month"
        expect(ivl_qle_sep.effective_on).to eq lapsed_effective_date
      end

      it "the effective date should be in the future: first of month following the plan shopping in IVL for lost insurance sep" do
        ivl_lost_insurance_qle_sep.effective_on_kind = "first_of_next_month"
        expect(ivl_lost_insurance_qle_sep.effective_on).to eq TimeKeeper.date_of_record.next_month.beginning_of_month
      end

      it "the effective date should not be in future: first of month following the lapsed date in SHOP for lost insurance sep" do
        shop_lost_insurance_qle_sep.effective_on_kind = "first_of_next_month"
        expect(shop_lost_insurance_qle_sep.effective_on).not_to eq TimeKeeper.date_of_record.next_month.beginning_of_month
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

  let(:family) { FactoryBot.build(:family, :with_primary_family_member) }
  let(:primary_applicant) { double }
  let(:person) { FactoryBot.create(:person, :with_employee_role) }
  let(:event_date) { TimeKeeper.date_of_record }
  let(:expired_event_date) { TimeKeeper.date_of_record - 1.year }
  let(:first_of_following_month) { TimeKeeper.date_of_record.end_of_month + 1 }
  let(:qle_effective_date) { FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date) }
  let(:qle_first_of_month) { FactoryBot.create(:qualifying_life_event_kind, :effective_on_first_of_month) }

  describe "it should set SHOP Special Enrollment Period dates based on QLE kind" do
    let(:sep_effective_date) { SpecialEnrollmentPeriod.new(qualifying_life_event_kind: qle_effective_date, effective_on_kind: 'date_of_event', qle_on: event_date) }
    let(:sep_first_of_month) { SpecialEnrollmentPeriod.new(qualifying_life_event_kind: qle_first_of_month, effective_on_kind: 'first_of_month', qle_on: event_date) }
    let(:sep_expired) { SpecialEnrollmentPeriod.new(qualifying_life_event_kind: qle_first_of_month, qle_on: expired_event_date) }
    let(:sep) { SpecialEnrollmentPeriod.new }
    let(:qle) { FactoryBot.create(:qualifying_life_event_kind, market_kind: 'shop', is_active: true) }


    context "SHOP QLE and event date are specified" do
      it "should set start_on date to date of event" do
        allow(family).to receive(:primary_applicant).and_return(primary_applicant)
        allow(primary_applicant).to receive(:person).and_return(person)
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

      it "and qle is date_of_event" do
        sep.qualifying_life_event_kind = qle
        sep.effective_on_kind = "date_of_event"
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

  context "#is_fehb?" do
    let(:ivl_qle_sep) { family.special_enrollment_periods.build(qualifying_life_event_kind: ivl_qle) }
    let(:shop_qle_sep) { family.special_enrollment_periods.build(qualifying_life_event_kind: shop_qle) }
    let(:fehb_qle_sep) { family.special_enrollment_periods.build(qualifying_life_event_kind: fehb_qle) }

    it "should return true when shop qle" do
      expect(shop_qle_sep.is_fehb?).to be_falsey
    end

    it "should return false when ivl qle" do
      expect(ivl_qle_sep.is_fehb?).to be_falsey
    end

    it "should return true when fehb qle" do
      expect(fehb_qle_sep.is_fehb?).to be_truthy
    end
  end

  context "#is_shop_or_fehb?" do
    let(:ivl_qle_sep) { family.special_enrollment_periods.build(qualifying_life_event_kind: ivl_qle) }
    let(:shop_qle_sep) { family.special_enrollment_periods.build(qualifying_life_event_kind: shop_qle) }
    let(:fehb_qle_sep) { family.special_enrollment_periods.build(qualifying_life_event_kind: fehb_qle) }

    it "should return true when shop qle" do
      expect(shop_qle_sep.is_shop_or_fehb?).to be_truthy
    end

    it "should return false when ivl qle" do
      expect(ivl_qle_sep.is_shop_or_fehb?).to be_falsey
    end

    it "should return true when fehb qle" do
      expect(fehb_qle_sep.is_shop_or_fehb?).to be_truthy
    end
  end


  context "is reporting a qle before the employer plan start_date" do
    let!(:published_plan_year) { FactoryBot.create(:next_month_plan_year) }
    let(:census_employee) { FactoryBot.create(:census_employee, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789', hired_on: Date.new(TimeKeeper.date_of_record.year, 03, 14)) }
    let(:shop_family)       { FactoryBot.create(:family, :with_primary_family_member)  }

    let(:sep){
      sep = shop_family.special_enrollment_periods.new
      sep.effective_on_kind = 'first_of_next_month'
      sep.qualifying_life_event_kind= qle_first_of_month
      sep.qle_on = published_plan_year.start_on - 16.days
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


  context "is reporting a qle before the employer plan start_date and having an expired plan year" do
    let(:organization) { FactoryBot.create(:organization, :with_expired_and_active_plan_years)}
    let(:census_employee) { FactoryBot.create :census_employee, employer_profile: organization.employer_profile, dob: TimeKeeper.date_of_record - 30.years,
                            first_name: person.first_name, last_name: person.last_name, ssn: person.ssn
                            }
    let(:employee_role) { FactoryBot.create(:employee_role, person: person, census_employee: census_employee, employer_profile: organization.employer_profile)}
    let(:person) { FactoryBot.create(:person)}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let(:sep) { FactoryBot.create(:special_enrollment_period, family: family)}

    it "should return a sep with an effective date that equals to sep date" do
      sep.update_attributes(:qle_on => organization.employer_profile.plan_years[0].end_on - 14.days )
      expect(sep.effective_on).to eq sep.qle_on
    end

    it "should return a sep with an effective date that equals to first of month" do
      sep.update_attribute(:effective_on_kind, "first_of_month")
      expect(sep.effective_on.day).to eq 1
    end
  end

  context "where employee role is not active" do
    let!(:person100)  { FactoryBot.create(:person, :with_consumer_role, :with_employee_role) }
    let!(:primary_applicant) { double }
    let!(:family100)  { FactoryBot.create(:family, :with_primary_family_member, person: person100) }
    let!(:qualifying_life_event_kind101)  { FactoryBot.create(:qualifying_life_event_kind) }
    let!(:special_enrollment_period100)  { SpecialEnrollmentPeriod.new(next_poss_effective_date: TimeKeeper.date_of_record,
                                                                       start_on: TimeKeeper.date_of_record, end_on: TimeKeeper.date_of_record + 1.month,
                                                                       qle_on: TimeKeeper.date_of_record, effective_on_kind: "first_of_next_month",
                                                                       qualifying_life_event_kind_id: qualifying_life_event_kind101.id) }

    it "sep should be save" do
      family100.special_enrollment_periods << special_enrollment_period100
      expect(family100.special_enrollment_periods.find(special_enrollment_period100.id.to_s).persisted?).to be_truthy
    end

    it "should not raise Exception" do
      expect{family100.special_enrollment_periods << special_enrollment_period100}.not_to raise_error
    end
  end

  context "where sep is ivl but QLE is shop" do
    let!(:person100)  { FactoryBot.create(:person, :with_consumer_role, :with_employee_role) }
    let!(:primary_applicant) { double }
    let!(:family100)  { FactoryBot.create(:family, :with_primary_family_member, person: person100) }
    let!(:qualifying_life_event_kind101)  { FactoryBot.create(:qualifying_life_event_kind) }
    let!(:special_enrollment_period100)  { SpecialEnrollmentPeriod.new(next_poss_effective_date: TimeKeeper.date_of_record,
                                                                       start_on: TimeKeeper.date_of_record, end_on: TimeKeeper.date_of_record + 1.month,
                                                                       qle_on: TimeKeeper.date_of_record, effective_on_kind: "first_of_next_month",
                                                                       qualifying_life_event_kind_id: qualifying_life_event_kind101.id, market_kind: "ivl") }

    before :each do
      allow(person100).to receive(:has_active_employee_role?).and_return(true)
    end

    it "should not raise Exception" do
      expect{family100.special_enrollment_periods << special_enrollment_period100}.not_to raise_error
    end


    it "should add error messages to the instance" do
      family100.special_enrollment_periods << special_enrollment_period100
      expect(family100.special_enrollment_periods[0].errors.messages).to eq({:next_poss_effective_date=>["No active plan years present"]})
    end
  end

  context "where employee role is active" do
    let!(:person100)  { FactoryBot.create(:person, :with_consumer_role, :with_employee_role) }
    let!(:primary_applicant) { double }
    let!(:family100)  { FactoryBot.create(:family, :with_primary_family_member, person: person100) }
    let!(:qualifying_life_event_kind101)  { FactoryBot.create(:qualifying_life_event_kind) }
    let!(:special_enrollment_period100)  { SpecialEnrollmentPeriod.new(next_poss_effective_date: TimeKeeper.date_of_record,
                                                                       start_on: TimeKeeper.date_of_record, end_on: TimeKeeper.date_of_record + 1.month,
                                                                       qle_on: TimeKeeper.date_of_record, effective_on_kind: "first_of_next_month",
                                                                       optional_effective_on: ["#{TimeKeeper.date_of_record + 5.days}"],
                                                                       qualifying_life_event_kind_id: qualifying_life_event_kind101.id) }
    before :each do
      allow(person100).to receive(:has_active_employee_role?).and_return(true)
    end

    it "should not raise Exception" do
      expect{family100.special_enrollment_periods << special_enrollment_period100}.not_to raise_error
    end

    it "should add error messages to the instance" do
      family100.special_enrollment_periods << special_enrollment_period100
      expect(family100.special_enrollment_periods[0].errors.messages). to eq({:optional_effective_on=>["No active plan years present"]})
    end
  end

  context '.set_effective_on' do

    let(:valid_params){
      {
        family: family,
        qualifying_life_event_kind: qle,
        qle_on: qle_on,
      }
    }

    let(:params) { valid_params.merge(qle_on: qle_on, effective_on_kind: effective_on_kind) }
    let(:special_enrollment_period) { SpecialEnrollmentPeriod.new(**params) }

    let!(:qle) { create(:qualifying_life_event_kind, title: "covid-19", market_kind: "shop", reason: "covid-19") }

    let!(:sep) do
      sep = special_enrollment_period
      sep.save
      sep
    end

    context 'when first_of_this_month is selected' do
      let(:effective_on_kind) { 'first_of_this_month' }

      context 'qle_on is middle of month' do
        let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month + 15.days }

        it 'should set effective date as beginning of current month' do 
          expect(sep.effective_on).to eq qle_on.beginning_of_month
        end
      end

      context 'qle_on is beginning of momth' do
        let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month }

        it 'should set effective date as beginning of current month' do 
          expect(sep.effective_on).to eq qle_on.beginning_of_month
        end
      end
    end

    context 'when fixed_first_of_next_month is selected' do
      let(:effective_on_kind) { 'fixed_first_of_next_month' }

      context 'qle_on is middle of month' do
        let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month + 15.days }

        it 'should set effective date as beginning of next month' do 
          expect(sep.effective_on).to eq qle_on.end_of_month + 1.day
        end
      end

      context 'qle_on is beginning of momth' do
        let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month }

        it 'should set effective date as beginning of next month' do 
          expect(sep.effective_on).to eq qle_on.end_of_month + 1.day
        end
      end
    end

    context 'when date_of_event is selected' do
      let(:effective_on_kind) { 'date_of_event' }

      context 'qle_on is middle of month' do
        let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month + 15.days }

        it 'should set effective date as event date' do
          expect(sep.effective_on).to eq qle_on
        end
      end

      context 'qle_on is beginning of momth' do
        let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month }

        it 'should set effective date as event date' do
          expect(sep.effective_on).to eq qle_on
        end
      end
    end

    context 'when first_of_month is selected' do

      after :all do
        TimeKeeper.set_date_of_record_unprotected!(Date.today)
      end

      let(:effective_on_kind) { 'first_of_month' }
      let(:new_sep) { family.special_enrollment_periods.build(qualifying_life_event_kind: ivl_qle, qle_on: qle_on, effective_on_kind: effective_on_kind) }

      context "IVL" do
        let!(:qle) { create(:qualifying_life_event_kind, market_kind: "individual") }

        context 'qle_on is middle of month, reporting_date before 15th of month' do
          let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month + 16.days }
          let(:reporting_date) { TimeKeeper.date_of_record.beginning_of_month }

          before do
            TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          end

          it 'should set effective date as next month beginning of month from qle' do
            expect(new_sep.effective_on).to eq qle_on.end_of_month + 1.day
          end
        end

        context 'qle_on is beginning of month, reporting_date before 15th of month' do
          let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month }
          let(:reporting_date) { TimeKeeper.date_of_record.beginning_of_month }

          before do
            TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          end

          it 'should set effective date as next month beginning of month from qle' do
            expect(new_sep.effective_on).to eq qle_on.end_of_month + 1.day
          end
        end

        context 'qle_on is middle of month, reporting_date after 15th of month' do

          let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month + 16.days }
          let!(:reporting_date) { TimeKeeper.date_of_record.beginning_of_month + 16.days }

          before do
            TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          end

          it 'should set effective date as next of next month beginning of month' do
            expect(new_sep.effective_on).to eq [qle_on, reporting_date].max.next_month.end_of_month + 1.day
          end
        end

        context 'qle_on is beginning of month, reporting_date after 15th of month' do
          let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month }
          let!(:reporting_date) { TimeKeeper.date_of_record.beginning_of_month + 16.days }

          before do
            TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          end

          it 'should set effective date as next of next month beginning of month' do
            expect(new_sep.effective_on).to eq [qle_on, reporting_date].max.next_month.end_of_month + 1.day
          end
        end
      end

      context "SHOP" do

        context 'qle_on is middle of month, reporting_date before 15th of month' do
          let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month + 16.days }
          let(:reporting_date) { TimeKeeper.date_of_record.beginning_of_month }

          before do
            TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          end

          it 'should set effective date as next month beginning of month from qle' do
            expect(new_sep.effective_on).to eq qle_on.end_of_month + 1.day
          end
        end

        context 'qle_on is beginning of month, reporting_date before 15th of month' do
          let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month }
          let(:reporting_date) { TimeKeeper.date_of_record.beginning_of_month }

          before do
            TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          end

          it 'should set effective date as next month beginning of month from qle' do
            expect(new_sep.effective_on).to eq qle_on.end_of_month + 1.day
          end
        end

        context 'qle_on is middle of month, reporting_date after 15th of month' do

          let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month + 16.days }
          let!(:reporting_date) { TimeKeeper.date_of_record.beginning_of_month + 16.days }

          before do
            TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          end

          it 'should set effective date as next of next month beginning of month' do
            expect(new_sep.effective_on).to eq [qle_on, reporting_date].max.next_month.end_of_month + 1.day
          end
        end

        context 'qle_on is beginning of month, reporting_date after 15th of month' do
          let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month }
          let!(:reporting_date) { TimeKeeper.date_of_record.beginning_of_month + 16.days }

          before do
            TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          end

          it 'should set effective date as next of next month beginning of month' do
            expect(new_sep.effective_on).to eq [qle_on, reporting_date].max.next_month.end_of_month + 1.day
          end
        end
      end
    end

    context 'when first_of_next_month is selected' do
      let(:effective_on_kind) { 'first_of_next_month' }

      context "SHOP" do
        context 'qle_on is middle of month' do
          let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month + 15.days }

          it 'should set effective date as beginning of next month' do
            expect(sep.effective_on).to eq qle_on.end_of_month + 1.day
          end
        end

        context 'qle_on is beginning of momth' do
          let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month }

          it 'should set effective date as beginning of next month' do
            expect(sep.effective_on).to eq qle_on
          end
        end
      end

      context "IVL" do
        let!(:ivl_qle) { create(:qualifying_life_event_kind, market_kind: "individual") }

        before do
          sep.update_attributes(qualifying_life_event_kind: ivl_qle)
        end

        context 'qle_on is middle of month' do
          let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month + 15.days }

          it 'should set effective date as beginning of next month' do
            expect(sep.effective_on).to eq qle_on.end_of_month + 1.day
          end
        end

        context 'qle_on is beginning of momth' do
          let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month }

          it 'should set effective date as beginning of next month' do
            expect(sep.effective_on).to eq qle_on.end_of_month + 1.day
          end
        end
      end
    end

    context 'when first_of_reporting_month is selected' do
      let(:effective_on_kind) { 'first_of_reporting_month' }

      context 'qle_on is middle of month' do
        let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month + 15.days }

        it 'should set effective date as beginning of next month from qle' do
          expect(sep.effective_on).to eq qle_on.next_month.beginning_of_month
        end
      end

      context 'qle_on is beginning of month' do
        let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month }

        it 'should set effective date as beginning of next month from qle' do
          expect(sep.effective_on).to eq qle_on.next_month.beginning_of_month
        end
      end

      context 'qle_on is last month' do
        let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month - 1.day }

        it 'should set effective date as beginning of month from reporting' do
          expect(sep.effective_on).to eq TimeKeeper.date_of_record.beginning_of_month
        end
      end

      context 'qle_on is future month' do
        let(:qle_on) { TimeKeeper.date_of_record.next_month.beginning_of_month }

        it 'should set effective date as beginning of next month from qle' do
          expect(sep.effective_on).to eq qle_on.end_of_month + 1.day
        end
      end
    end

    context 'when first_of_next_month_reporting is selected' do
      let(:effective_on_kind) { 'first_of_next_month_reporting' }

      context 'qle_on is middle of month' do
        let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month + 15.days }

        it 'should set effective date as beginning of next month from reporting' do
          expect(sep.effective_on).to eq TimeKeeper.date_of_record.next_month.beginning_of_month
        end
      end

      context 'qle_on is beginning of momth' do
        let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month }

        it 'should set effective date as beginning of next month from reporting' do
          expect(sep.effective_on).to eq TimeKeeper.date_of_record.next_month.beginning_of_month
        end
      end

      context 'qle_on is last month' do
        let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month - 1.day }

        it 'should set effective date as beginning of next month from reporting' do
          expect(sep.effective_on).to eq TimeKeeper.date_of_record.next_month.beginning_of_month
        end
      end

      context 'qle_on is future month' do
        let(:qle_on) { TimeKeeper.date_of_record.next_month.beginning_of_month }

        it 'should set effective date as next month from qle' do
          expect(sep.effective_on).to eq qle_on.end_of_month + 1.day
        end
      end
    end

    context 'when date_of_event_plus_one is selected' do
      let(:effective_on_kind) { 'date_of_event_plus_one' }

      context 'qle_on is middle of month' do
        let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month }

        it 'should set effective date as next day of event date' do
          expect(sep.effective_on).to eq qle_on + 1.day
        end
      end
    end

    context 'when first_of_next_month_coinciding is selected' do
      after :all do
        TimeKeeper.set_date_of_record_unprotected!(Date.today)
      end
      let(:effective_on_kind) { 'first_of_next_month_coinciding' }
      let(:new_sep) { family.special_enrollment_periods.build(qualifying_life_event_kind: ivl_qle, qle_on: qle_on, effective_on_kind: effective_on_kind) }

      context "IVL" do
        let!(:qle) { create(:qualifying_life_event_kind, market_kind: "individual") }

        context 'qle_on second day of month, submitted date after qle date' do
          let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month + 1.days }
          let(:reporting_date) { TimeKeeper.date_of_record.beginning_of_month + 2.day }

          before do
            TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          end

          it 'should set effective date as next month beginning of month from qle on' do
            expect(new_sep.effective_on).to eq qle_on.end_of_month + 1.day
          end
        end

        context 'qle_on past month, submitted date after qle date' do
          let(:qle_on) { TimeKeeper.date_of_record.last_month }
          let(:reporting_date) { TimeKeeper.date_of_record }
          before do
            TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          end

          it 'should set effective date as next month beginning of month from qle' do
            expect(new_sep.effective_on).to eq qle_on.end_of_month + 1.day
          end
        end

        context 'qle_on future, reporting_date after 15th of month' do
          let(:qle_on) { TimeKeeper.date_of_record.next_month }
          let!(:reporting_date) { TimeKeeper.date_of_record }
          before do
            TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          end

          it 'should set effective date as next month beginning of month from qle' do
            expect(new_sep.effective_on).to eq qle_on.end_of_month + 1.day
          end
        end

        context 'qle_on & submitted date first of month' do
          let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month }
          let!(:reporting_date) { TimeKeeper.date_of_record.beginning_of_month }
          before do
            TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          end

          it 'should set effective date as beginning of month' do
            expect(new_sep.effective_on).to eq TimeKeeper.date_of_record.beginning_of_month
          end
        end
      end

      context "SHOP" do
        context 'qle_on second day of month, submitted date after qle date' do
          let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month + 1.day }
          let(:reporting_date) { TimeKeeper.date_of_record.beginning_of_month + 2.day }
          before do
            TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          end

          it 'should set effective date as next month beginning of month from qle' do
            expect(new_sep.effective_on).to eq qle_on.end_of_month + 1.day
          end
        end

        context 'qle_on past month, submitted date after qle date' do
          let(:qle_on) { TimeKeeper.date_of_record.last_month }
          let(:reporting_date) { TimeKeeper.date_of_record }
          before do
            TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          end

          it 'should set effective date as next month beginning of month from qle' do
            expect(new_sep.effective_on).to eq qle_on.end_of_month + 1.day
          end
        end

        context 'qle_on future, reporting_date after 15th of month' do
          let(:qle_on) { TimeKeeper.date_of_record.next_month }
          let!(:reporting_date) { TimeKeeper.date_of_record }
          before do
            TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          end

          it 'should set effective date as next month beginning of month from qle' do
            expect(new_sep.effective_on).to eq qle_on.end_of_month + 1.day
          end
        end

        context 'qle_on & submitted date first of month' do
          let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month }
          let!(:reporting_date) { TimeKeeper.date_of_record.beginning_of_month }
          before do
            TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          end

          it 'should set effective date as beginning of month' do
            expect(new_sep.effective_on).to eq TimeKeeper.date_of_record.beginning_of_month
          end
        end
      end
    end

    context 'when first_of_next_month_plan_selection is selected' do
      after :all do
        TimeKeeper.set_date_of_record_unprotected!(Date.today)
      end
      let(:effective_on_kind) { 'first_of_next_month_plan_selection' }
      let(:new_sep) { family.special_enrollment_periods.build(qualifying_life_event_kind: ivl_qle, qle_on: qle_on, effective_on_kind: effective_on_kind) }

      context "IVL" do
        let!(:qle) { create(:qualifying_life_event_kind, market_kind: "individual") }

        context 'qle_on current month, submitted date after qle date' do
          let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month }
          let(:reporting_date) { TimeKeeper.date_of_record.beginning_of_month + 1.day }
          before do
            TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          end

          it 'should set effective date as next month beginning of month from reporting' do
            expect(new_sep.effective_on).to eq reporting_date.end_of_month + 1.day
          end
        end

        context 'qle_on past month, submitted date after qle date' do
          let(:qle_on) { TimeKeeper.date_of_record.last_month }
          let(:reporting_date) { TimeKeeper.date_of_record }
          before do
            TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          end

          it 'should set effective date as next month beginning of month from reporting' do
            expect(new_sep.effective_on).to eq reporting_date.end_of_month + 1.day
          end
        end

        context 'qle_on future, reporting_date after 15th of month' do
          let(:qle_on) { TimeKeeper.date_of_record.next_month }
          let!(:reporting_date) { TimeKeeper.date_of_record }
          before do
            TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          end

          it 'should set effective date as next of next month beginning of month' do
            expect(new_sep.effective_on).to eq qle_on.end_of_month + 1.day
          end
        end
      end

      context "SHOP" do
        context 'qle_on current month, submitted date after qle date' do
          let(:qle_on) { TimeKeeper.date_of_record.beginning_of_month }
          let(:reporting_date) { TimeKeeper.date_of_record.beginning_of_month + 1.day }
          before do
            TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          end

          it 'should set effective date as next month beginning of month from reporting' do
            expect(new_sep.effective_on).to eq reporting_date.end_of_month + 1.day
          end
        end

        context 'qle_on past month, submitted date after qle date' do
          let(:qle_on) { TimeKeeper.date_of_record.last_month }
          let(:reporting_date) { TimeKeeper.date_of_record }
          before do
            TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          end

          it 'should set effective date as next month beginning of month from reporting' do
            expect(new_sep.effective_on).to eq reporting_date.end_of_month + 1.day
          end
        end

        context 'qle_on future, reporting_date after 15th of month' do
          let(:qle_on) { TimeKeeper.date_of_record.next_month }
          let!(:reporting_date) { TimeKeeper.date_of_record }
          before do
            TimeKeeper.set_date_of_record_unprotected!(reporting_date)
          end

          it 'should set effective date as next of next month beginning of month' do
            expect(new_sep.effective_on).to eq qle_on.end_of_month + 1.day
          end
        end
      end
    end
  end

  context 'for termination_dates' do

    context "term dates for termination kinds" do
      let!(:family10) { FactoryBot.create(:family, :with_primary_family_member) }
      let!(:sep10) do
        sep = FactoryBot.create(:special_enrollment_period, family: family10)
        sep.qualifying_life_event_kind.update_attributes!(termination_on_kinds: ['end_of_event_month', 'exact_date'])
        sep
      end

      before do
        @termination_dates = sep10.termination_dates(TimeKeeper.date_of_record - 20.days)
      end

      it 'should include sep qle_on' do
        expect(@termination_dates).to include(sep10.qle_on)
      end

      it 'should include end_of_month of sep qle_on' do
        expect(@termination_dates).to include(sep10.qle_on.end_of_month)
      end

      context 'effective_on_date is greater than qle_on' do
        before do
          @termination_dates = sep10.termination_dates(TimeKeeper.date_of_record)
        end

        it 'should not include qle_on for exact_date' do
          expect(@termination_dates).not_to include(sep10.qle_on)
        end

        it 'should include given date and not qle_on' do
          expect(@termination_dates).to include(TimeKeeper.date_of_record)
        end
      end
    end

    context 'duplicate terminate dates' do
      let!(:family) { FactoryBot.create(:family, :with_primary_family_member) }
      let!(:sep) do
        sep = FactoryBot.create(:special_enrollment_period, family: family)
        sep.qualifying_life_event_kind.update_attributes!(termination_on_kinds: ['end_of_event_month', 'exact_date', 'date_before_event','end_of_last_month_of_reporting','end_of_reporting_month', 'end_of_month_before_last'])
        sep
      end

      it 'should not have duplicate term dates' do
        @termination_dates = sep.termination_dates(TimeKeeper.date_of_record - 20.days)
        expect(@termination_dates.select { |date| @termination_dates.count(date) > 1 }).to eq []
      end
    end
  end

  context 'for fetch_termiation_date' do
    let!(:family10) { FactoryBot.create(:family, :with_primary_family_member) }
    let!(:qle_on) { TimeKeeper.date_of_record - 10.days }
    let!(:sep10) do
      sep = FactoryBot.create(:special_enrollment_period, qle_on: qle_on, family: family10)
      sep.qualifying_life_event_kind.update_attributes!(termination_on_kinds: ['end_of_event_month', 'exact_date'])
      sep
    end

    it 'should return end_of_month of sep qle_on' do
      expect(sep10.fetch_termiation_date('end_of_event_month')).to eq(sep10.qle_on.end_of_month)
    end

    context "end_of_month_before_last" do
      context "qle on past month" do
        let!(:qle_on) { TimeKeeper.date_of_record - 3.months }
        it 'should return end of last of last month from reporting date' do
          expect(sep10.fetch_termiation_date('end_of_month_before_last')).to eq((sep10.created_at - 2.months).end_of_month.to_date)
        end
      end

      context "qle on current month" do
        let!(:qle_on) { TimeKeeper.date_of_record }
        it 'should return end month from event date' do
          expect(sep10.fetch_termiation_date('end_of_month_before_last')).to eq(sep10.qle_on.end_of_month)
        end
      end

      context "qle on future month" do
        let!(:qle_on) { TimeKeeper.date_of_record.next_month }
        it 'should return end month from event date' do
          expect(sep10.fetch_termiation_date('end_of_month_before_last')).to eq(sep10.qle_on.end_of_month)
        end
      end
    end

    it 'should return day before qle_on' do
      expect(sep10.fetch_termiation_date('date_before_event')).to eq(sep10.qle_on - 1.day)
    end

    context "end_of_last_month_of_reporting" do
      context "qle on past month" do
        let!(:qle_on) { TimeKeeper.date_of_record - 2.months }
        it 'should return end_of_month of previous month of sep submitted_at date' do
          expect(sep10.fetch_termiation_date('end_of_last_month_of_reporting')).to eq(sep10.created_at.prev_month.end_of_month.to_date)
        end
      end

      context "qle on current month" do
        let!(:qle_on) { TimeKeeper.date_of_record }
        it 'should return end month from event date' do
          expect(sep10.fetch_termiation_date('end_of_last_month_of_reporting')).to eq(sep10.qle_on.end_of_month)
        end
      end

      context "qle on future month" do
        let!(:qle_on) { TimeKeeper.date_of_record.next_month }
        it 'should return end month from event date' do
          expect(sep10.fetch_termiation_date('end_of_last_month_of_reporting')).to eq(sep10.qle_on.end_of_month)
        end
      end
    end

    context "end_of_reporting_month" do
      context "qle on past month" do
        let!(:qle_on) { TimeKeeper.date_of_record - 2.months }
        it 'should return end_of_month of sep submitted_at date' do
          expect(sep10.fetch_termiation_date('end_of_reporting_month')).to eq(sep10.created_at.end_of_month.to_date)
        end
      end

      context "qle on current month" do
        let!(:qle_on) { TimeKeeper.date_of_record }
        it 'should return end month from event date' do
          expect(sep10.fetch_termiation_date('end_of_reporting_month')).to eq(sep10.created_at.end_of_month.to_date)
        end
      end

      context "qle on future month" do
        let!(:qle_on) { TimeKeeper.date_of_record.next_month }
        it 'should return end month from event date' do
          expect(sep10.fetch_termiation_date('end_of_reporting_month')).to eq(sep10.qle_on.end_of_month)
        end
      end
    end

    it 'should return sep qle_on date' do
      expect(sep10.fetch_termiation_date('exact_date')).to eq(sep10.qle_on)
    end
  end

  context 'set_date_period' do

    let(:qle_on) { TimeKeeper.date_of_record - 2.days}

    context 'QLEK with coverage_start_on & coverage_end_on dates' do
      let!(:qle) { create(:qualifying_life_event_kind, pre_event_sep_in_days: 0, post_event_sep_in_days: 30, coverage_start_on: TimeKeeper.date_of_record.last_month, coverage_end_on: TimeKeeper.date_of_record.end_of_month) }
      let!(:sep) do
        subject.qualifying_life_event_kind = qle
        subject
      end

      it 'should return sep range' do
        sep_dates = sep.send(:set_date_period)
        date = (subject.created_at ||= TimeKeeper.date_of_record).to_date
        expect(sep_dates).to eq date..date + qle.post_event_sep_in_days.days
      end

      it 'should set start on based qle submitted' do
        sep.send(:set_date_period)
        date = (subject.created_at ||= TimeKeeper.date_of_record).to_date
        expect(sep.start_on).to eq date
      end

      it 'should set end on based qle submitted' do
        sep.send(:set_date_period)
        date = (subject.created_at ||= TimeKeeper.date_of_record).to_date
        expect(sep.end_on).to eq date + qle.post_event_sep_in_days.days
      end
    end

    context 'QLEK without coverage_start_on & coverage_end_on dates' do
      let!(:qle) { create(:qualifying_life_event_kind, pre_event_sep_in_days: 0, post_event_sep_in_days: 30) }
      let!(:sep) do
        subject.qualifying_life_event_kind = qle
        subject.qle_on = qle_on
        subject
      end

      it 'should return sep range' do
        sep_dates = sep.send(:set_date_period)
        expect(sep_dates).to eq qle_on..qle_on + qle.post_event_sep_in_days.days
      end

      it 'should set start on based qle_on' do
        sep.send(:set_date_period)
        expect(sep.start_on).to eq qle_on
      end

      it 'should set end on based qle_on' do
        sep.send(:set_date_period)
        expect(sep.end_on).to eq qle_on + qle.post_event_sep_in_days.days
      end
    end

    context 'qualifying life event kind with qle_event_date_kind == submitted_at' do
      let!(:qle) { create(:qualifying_life_event_kind, pre_event_sep_in_days: 0, post_event_sep_in_days: 30, coverage_start_on: TimeKeeper.date_of_record.last_month, coverage_end_on: TimeKeeper.date_of_record.end_of_month) }
      let!(:sep) do
        subject.qualifying_life_event_kind = qle
        subject
      end

      it 'should return sep range' do
        sep_dates = sep.send(:set_date_period)
        date = (subject.created_at ||= TimeKeeper.date_of_record).to_date
        expect(sep_dates).to eq date..date + qle.post_event_sep_in_days.days
      end

      it 'should set start on based qle created' do
        sep.send(:set_date_period)
        date = (subject.created_at ||= TimeKeeper.date_of_record).to_date
        expect(sep.start_on).to eq date
      end

      it 'should set end on based qle created' do
        sep.send(:set_date_period)
        date = (subject.created_at ||= TimeKeeper.date_of_record).to_date
        expect(sep.end_on).to eq date + qle.post_event_sep_in_days.days
      end
    end
  end
end
