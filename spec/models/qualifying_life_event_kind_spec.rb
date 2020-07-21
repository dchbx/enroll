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
        post_event_sep_in_days: 30,
        is_active: true
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

  context 'new ivl coverall qles'do

    after(:each) do
      DatabaseCleaner.clean
    end

    it 'should not display transition member action kind qle' do
      qle1 = FactoryBot.create(:qualifying_life_event_kind, market_kind: 'individual', action_kind: "transition_member")
      qle2 = FactoryBot.create(:qualifying_life_event_kind, market_kind: 'individual', action_kind: "add_member")
      expect(QualifyingLifeEventKind.individual_market_events_without_transition_member_action).to include(qle2)
      expect(QualifyingLifeEventKind.individual_market_events_without_transition_member_action).not_to include(qle1)
    end

    it 'should display transition member action kind qle' do
      qle1 = FactoryBot.create(:qualifying_life_event_kind, market_kind: 'individual', action_kind: "transition_member")
      qle2 = FactoryBot.create(:qualifying_life_event_kind, market_kind: 'individual', action_kind: "add_member")
      expect(QualifyingLifeEventKind.individual_market_events_admin.count). to eq 2
      expect(QualifyingLifeEventKind.individual_market_events_admin).to include(qle1, qle2)
    end
  end

  describe "instance methods" do
    let(:esi_qlek) {FactoryBot.create(:qualifying_life_event_kind, title: "Dependent loss of employer-sponsored insurance because employee is enrolling in Medicare ", reason: "employee_gaining_medicare")}
    let(:moved_qlek) {FactoryBot.create(:qualifying_life_event_kind, title: "Moved or moving to the #{Settings.aca.state_name}", reason: "relocate")}
    let(:qle) {FactoryBot.create(:qualifying_life_event_kind, title: "Employer did not pay premiums on time", reason: 'employer_sponsored_coverage_termination')}

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
        qle = FactoryBot.build(:qualifying_life_event_kind, market_kind: "individual")
        expect(qle.individual?).to eq true
      end

      it "return false" do
        qle = FactoryBot.build(:qualifying_life_event_kind, market_kind: "shop")
        expect(qle.individual?).to eq false
      end
    end

    context "family_structure_changed?" do
      it "return true" do
        %w(birth adoption marriage divorce domestic_partnership).each do |reason|
          qle = FactoryBot.build(:qualifying_life_event_kind, reason: reason)
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

    context "active?" do
      let(:valid_params)do
        {
          title: "Married",
          market_kind: "shop",
          reason: "marriage",
          effective_on_kinds: ["first_of_month"],
          pre_event_sep_in_days: 0,
          post_event_sep_in_days: 30,
          is_active: true
        }
      end

      let(:qlek){ QualifyingLifeEventKind.create(**params)}

      context "when is_active set to false" do
        let(:params) { valid_params.merge({is_active: false}) }

        it 'should return false' do
          expect(qlek.active?).to be_falsey
        end
      end

      context "when end_on is nil" do
        let(:params) { valid_params.merge({start_on: TimeKeeper.date_of_record.beginning_of_year, end_on: nil}) }

        it 'should return true' do
          expect(qlek.active?).to be_truthy
        end
      end

      context "when qle end_on is in the past (expired)" do
        let(:params) { valid_params.merge({start_on: TimeKeeper.date_of_record.prev_month.beginning_of_month, end_on: TimeKeeper.date_of_record.prev_month.end_of_month}) }

        it 'should return false' do
          expect(qlek.active?).to be_falsey
        end
      end
    end
  end

  describe "date_guards" do

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

    let(:params){ valid_params.merge(date_params) }
    let(:qlek){ QualifyingLifeEventKind.create(**params)}

    context "when end_on passed and start_on missing" do
      let(:date_params) do
        {
          start_on: nil,
          end_on: TimeKeeper.date_of_record.end_of_month
        }
      end

      it "should fail validation" do
        expect(qlek.valid?).to be_falsey
        expect(qlek.errors[:start_on]).to eq ['start_on cannot be nil when end_on date present']
      end
    end

    context "when end_on date precedes start_on" do
      let(:date_params) do
        {
          start_on: TimeKeeper.date_of_record.beginning_of_month,
          end_on: TimeKeeper.date_of_record.prev_month
        }
      end

      it "should fail validation" do
        expect(qlek.valid?).to be_falsey
        expect(qlek.errors[:end_on]).to eq ['end_on cannot preceed start_on date']
      end
    end

    context "when valid start_on and end_on dates passed" do
      let(:date_params) do
        {
          start_on: TimeKeeper.date_of_record.beginning_of_month,
          end_on: TimeKeeper.date_of_record.end_of_month
        }
      end

      it "should succeed validation" do
        expect(qlek.valid?).to be_truthy
      end
    end

    context "when both start_on and end_on dates are blank" do
      let(:date_params) do
        {
          start_on: nil,
          end_on: nil
        }
      end

      it "should succeed validation" do
        expect(qlek.valid?).to be_truthy
      end
    end
  end

  describe "by_date" do

    context "when expired, active, future active qles present" do

      let!(:expired_qle) { create(:qualifying_life_event_kind, title: "Entered into a legal domestic partnership", market_kind: "shop", reason: "domestic_partnership", start_on: TimeKeeper.date_of_record.prev_month.beginning_of_month, end_on: TimeKeeper.date_of_record.prev_month.end_of_month)}
      let!(:active_qle1) { create(:qualifying_life_event_kind, title: "Had a Baby", market_kind: "shop", reason: "birth", start_on: nil, end_on: nil)}
      let!(:active_qle2) { create(:qualifying_life_event_kind, title: "Adopted a Child", market_kind: "shop", reason: "adoption", start_on: TimeKeeper.date_of_record.beginning_of_month, end_on: TimeKeeper.date_of_record.end_of_month)}
      let!(:active_qle3) { create(:qualifying_life_event_kind, title: "Married", market_kind: "shop", reason: "marriage", start_on: TimeKeeper.date_of_record.beginning_of_month, end_on: nil)}
      let!(:future_qle1) { create(:qualifying_life_event_kind, title: "Health plan contract violation", market_kind: "shop", reason: "contract_violation", start_on: TimeKeeper.date_of_record.next_month.beginning_of_month, end_on: nil)}
      let!(:future_qle2) { create(:qualifying_life_event_kind, title: "Exceptional circumstances", market_kind: "shop", reason: "exceptional_circumstances", start_on: TimeKeeper.date_of_record.next_month.beginning_of_month, end_on: TimeKeeper.date_of_record.next_month.end_of_month)}

      it "should return only active qles by date" do
        result = QualifyingLifeEventKind.by_date.to_a
        # expect(result.count).to eq 3
        expect(result).to include active_qle1
        expect(result).to include active_qle2
        expect(result).to include active_qle3
      end
    end
  end

  context 'aasm states' do
    context 'update_qle_reason_types' do
      context 'for adding a reason' do
        let!(:qlek) do
          FactoryBot.create(:qualifying_life_event_kind,
                            aasm_state: :draft,
                            reason: 'add reason')
        end

        before do
          qlek.publish!
        end

        it 'should include new reason in the ShopQleReasons type' do
          expect(::Types::ShopQleReasons.values).to include(qlek.reason)
        end
      end

      context 'for removing a reason' do
        let!(:qlek) do
          FactoryBot.create(:qualifying_life_event_kind,
                            aasm_state: :active,
                            reason: 'remove reason',
                            start_on: (TimeKeeper.date_of_record - 50.days),
                            end_on: (TimeKeeper.date_of_record - 30.days))
        end

        before do
          qlek.expire!
        end

        it 'should remove reason from the ShopQleReasons type' do
          expect(::Types::ShopQleReasons.values).not_to include(qlek.reason)
        end
      end
    end
  end
end
