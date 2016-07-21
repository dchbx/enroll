require 'rails_helper'

RSpec.describe QualifyingLifeEventKind, :type => :model do
  it { should validate_presence_of :title }
  it { should validate_presence_of :market_kind }
  it { should validate_presence_of :effective_on_kinds }
  it { should validate_presence_of :pre_event_sep_in_days }
  it { should validate_presence_of :post_event_sep_in_days }

  describe "class methods" do
    let(:valid_params)do
      {
        title: "Married",
        market_kind: "shop",
        reason: "marriage",
        effective_on_kinds: ["first_of_month"],
        pre_event_sep_in_days: 0,
        post_event_sep_in_days: 30
      }
    end

    context "should return a shop event kind" do
      let(:params){ valid_params }
      let(:qlek){ QualifyingLifeEventKind.create(**params)}
      before do
        qlek.valid?
      end
      it "when params are valid" do
        expect(QualifyingLifeEventKind.shop_market_events).to include(qlek)
        expect(QualifyingLifeEventKind.shop_market_events.first).to be_instance_of QualifyingLifeEventKind
      end
    end

    context "should return a individual event kind" do
      let(:params){ valid_params.deep_merge(market_kind: "individual") }
      let(:qlek){ QualifyingLifeEventKind.create(**params)}
      before do
        qlek.valid?
      end
      it "when params are valid" do
        expect(QualifyingLifeEventKind.individual_market_events).to include(qlek)
        expect(QualifyingLifeEventKind.individual_market_events.first).to be_instance_of QualifyingLifeEventKind
      end
    end


    context "should only display self-attested QLEs" do

      it "should display self-attested QLEs for shop market" do
        expect(QualifyingLifeEventKind.shop_market_events.first.is_self_attested == true)
      end

      it "should display self-attested QLEs for individual market" do
        expect(QualifyingLifeEventKind.individual_market_events.first.is_self_attested == true)
      end

      it "should not display non-self-attested QLEs for shop market" do
        expect(QualifyingLifeEventKind.shop_market_events.first.is_self_attested == false)
      end

      it "should not display non-self-attested QLEs for individual market" do
        expect(QualifyingLifeEventKind.individual_market_events.first.is_self_attested == false)
      end

    end


  end

  describe "instance methods" do
    let(:esi_qlek) {FactoryGirl.create(:qualifying_life_event_kind, title: "Dependent loss of employer-sponsored insurance because employee is enrolling in Medicare ", reason: "employee_gaining_medicare")}
    let(:moved_qlek) {FactoryGirl.create(:qualifying_life_event_kind, title: "Moved or moving to the #{Settings.aca.state_name}", reason: "relocate")}
    let(:qle) {FactoryGirl.create(:qualifying_life_event_kind, title: "Employer did not pay premiums on time", reason: 'employer_sponsored_coverage_termination')}

    before do
      TimeKeeper.set_date_of_record_unprotected!(Date.new(2015, 9, 15))
    end

    after :all do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end

    it "is_dependent_loss_of_coverage?" do
      expect(esi_qlek.is_dependent_loss_of_coverage?).to eq true
      expect(qle.is_dependent_loss_of_coverage?).to eq true
      expect(moved_qlek.is_dependent_loss_of_coverage?).to eq false
    end

    it "is_moved_to_dc?" do
      expect(esi_qlek.is_moved_to_dc?).to eq false
      expect(moved_qlek.is_moved_to_dc?).to eq true
    end

    context "individual?" do
      it "return true" do
        qle = FactoryGirl.build(:qualifying_life_event_kind, market_kind: "individual")
        expect(qle.individual?).to eq true
      end

      it "return false" do
        qle = FactoryGirl.build(:qualifying_life_event_kind, market_kind: "shop")
        expect(qle.individual?).to eq false
      end
    end

    context "family_structure_changed?" do
      it "return true" do
          %w(birth adoption marriage divorce domestic_partnership).each do |reason|
          qle = FactoryGirl.build(:qualifying_life_event_kind, reason: reason)
          expect(qle.family_structure_changed?).to eq true
        end
      end

      it "return false" do
        expect(moved_qlek.family_structure_changed?).to eq false
      end
    end

    context "employee_gaining_medicare" do
      let(:qle) {QualifyingLifeEventKind.new}

      context "when coverage_end_on is the last day of month" do
        it "plan selection <= coverage_end_on" do
          date = (TimeKeeper.date_of_record + 1.month).end_of_month
          expect(qle.employee_gaining_medicare(date)).to eq date + 1.day
        end

        it "plan selection > coverage_end_on" do
          date = (TimeKeeper.date_of_record - 1.month).end_of_month
          expect(qle.employee_gaining_medicare(date)).to eq TimeKeeper.date_of_record.end_of_month + 1.day
        end
      end

      context "when coverage_end_on is not the last day of month" do
        it "plan selected before the month in which coverage ends" do
          date = (TimeKeeper.date_of_record + 1.month).end_of_month.days_ago(3)
          results = [date.beginning_of_month, date.end_of_month + 1.day]
          expect(qle.employee_gaining_medicare(date)).to eq results
        end

        it "plan selected before the month in which coverage ends and has selected_effective_on" do
          date = (TimeKeeper.date_of_record + 1.month).end_of_month.days_ago(3)
          selected_on = TimeKeeper.date_of_record + 5.days
          results = [date.beginning_of_month, date.end_of_month + 1.day]
          expect(qle.employee_gaining_medicare(date, selected_on)).not_to eq results
          expect(qle.employee_gaining_medicare(date, selected_on)).to eq selected_on
        end

        it "plan selected during the month in which coverage ends" do
          date = (TimeKeeper.date_of_record).end_of_month.days_ago(3)
          results = (TimeKeeper.date_of_record + 1.month).beginning_of_month
          expect(qle.employee_gaining_medicare(date)).to eq results
        end

        it "plan selected after the month in which coverage ends" do
          date = (TimeKeeper.date_of_record - 1.month).end_of_month.days_ago(3)
          results = TimeKeeper.date_of_record.end_of_month + 1.day
          expect(qle.employee_gaining_medicare(date)).to eq results
        end
      end
    end
  end
end
