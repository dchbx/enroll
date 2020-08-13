require 'rails_helper'

RSpec.describe QualifyingLifeEventKind, :type => :model, dbclean: :after_each do

  describe "A new model instance", dbclean: :after_each do
    it { is_expected.to be_mongoid_document }
    it { is_expected.to have_fields(:event_kind_label).of_type(String)}
    it { is_expected.to have_field(:action_kind).of_type(String)}
    it { is_expected.to have_field(:title).of_type(String)}
    it { is_expected.to have_field(:effective_on_kinds).of_type(Array).with_default_value_of([])}
    it { is_expected.to have_field(:reason).of_type(String)}
    it { is_expected.to have_field(:edi_code).of_type(String)}
    it { is_expected.to have_field(:market_kind).of_type(String)}
    it { is_expected.to have_field(:tool_tip).of_type(String)}
    it { is_expected.to have_field(:pre_event_sep_in_days).of_type(Integer)}
    it { is_expected.to have_field(:is_self_attested).of_type(Mongoid::Boolean)}
    it { is_expected.to have_field(:date_options_available).of_type(Mongoid::Boolean)}
    it { is_expected.to have_field(:post_event_sep_in_days).of_type(Integer)}
    it { is_expected.to have_field(:ordinal_position).of_type(Integer)}
    it { is_expected.to have_field(:aasm_state).of_type(Symbol).with_default_value_of(:draft)}
    it { is_expected.to have_field(:is_active).of_type(Mongoid::Boolean)}
    it { is_expected.to have_field(:event_on).of_type(Date)}
    it { is_expected.to have_field(:qle_event_date_kind).of_type(Symbol).with_default_value_of(:qle_on)}
    it { is_expected.to have_field(:coverage_effective_on).of_type(Date)}
    it { is_expected.to have_field(:start_on).of_type(Date)}
    it { is_expected.to have_field(:end_on).of_type(Date)}
    it { is_expected.to have_field(:is_visible).of_type(Mongoid::Boolean)}
    it { is_expected.to have_field(:termination_on_kinds).of_type(Array).with_default_value_of([])}
    it { is_expected.to have_field(:coverage_end_on).of_type(Date)}
    it { is_expected.to have_field(:coverage_start_on).of_type(Date)}
    it { is_expected.to embed_many(:workflow_state_transitions)}
  end

  describe "required fields", dbclean: :after_each do
    it { should validate_presence_of :title }
    it { should validate_presence_of :market_kind }
    it { should validate_presence_of :effective_on_kinds }
    it { should validate_presence_of :pre_event_sep_in_days }
    it { should validate_presence_of :post_event_sep_in_days }
  end

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
      let!(:shop_self_attested) { create(:qualifying_life_event_kind, market_kind: "shop", is_self_attested: true)}
      let!(:shop_non_self_attested) { create(:qualifying_life_event_kind,  market_kind: "shop", is_self_attested: false)}
      let!(:ivl_self_attested) { create(:qualifying_life_event_kind, market_kind: "individual", is_self_attested: true)}
      let!(:ivl_non_self_attested) { create(:qualifying_life_event_kind, market_kind: "individual", is_self_attested: false)}

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

  context "qualifying_life_event_kind#event", dbclean: :after_each do

    context "publish", dbclean: :after_each do
      let!(:active_qlek) { create(:qualifying_life_event_kind, title: 'test_title', reason: 'test_reason', ordinal_position: 1, is_active: true, aasm_state: :active)}
      let!(:qlek) { create(:qualifying_life_event_kind, is_active: false, aasm_state: :draft)}

      context "sucess" do

        before do
          qlek.publish!
        end

        it "should transition from draft to :active state" do
          expect(qlek.aasm_state).to eq :active
        end

        it "is_active set to true" do
          expect(qlek.is_active).to eq true
        end

        it "should update ordinal position" do
          expect(qlek.ordinal_position).to eq 2
        end

        it "should create workflow_state_transition" do
          expect(qlek.workflow_state_transitions.count).to eq 1
          expect(qlek.workflow_state_transitions.first.from_state).to eq "draft"
          expect(qlek.workflow_state_transitions.first.to_state).to eq "active"
        end
      end

      context "failure" do
        it "title guard" do
          qlek.update_attributes(title: 'test_title')
          expect(qlek.may_publish?).to eq false
        end

        it "should raise error for invalid transition" do
          qlek.update_attributes(aasm_state: :active)
          expect { qlek.publish! }.to raise_error AASM::InvalidTransition
        end
      end

    end

    context "schedule_expiration", dbclean: :after_each do
      let!(:active_qlek) { create(:qualifying_life_event_kind, start_on: TimeKeeper.date_of_record.last_month, is_active: true, aasm_state: :active)}
      let!(:qlek) { create(:qualifying_life_event_kind, is_active: false, aasm_state: :draft)}

      context "sucess" do

        before do
          active_qlek.schedule_expiration!(TimeKeeper.date_of_record.next_day)
        end

        it "should transition from draft to :active state" do
          expect(active_qlek.aasm_state).to eq :expire_pending
        end

        it "should set end date" do
          expect(active_qlek.end_on).to eq TimeKeeper.date_of_record.next_day
        end

        it "should create workflow_state_transition" do
          expect(active_qlek.workflow_state_transitions.first.from_state).to eq "active"
          expect(active_qlek.workflow_state_transitions.first.to_state).to eq "expire_pending"
        end
      end

      context "failure" do

        it "can_be_expire_pending? guard" do
          expect(qlek.may_schedule_expiration?(TimeKeeper.date_of_record.next_day)).to eq false
        end

        it "should raise error for invalid transition" do
          expect { qlek.schedule_expiration!(TimeKeeper.date_of_record.next_day) }.to raise_error AASM::InvalidTransition
        end
      end
    end

    context "expire", dbclean: :after_each do

      let!(:active_qlek) { create(:qualifying_life_event_kind, start_on: TimeKeeper.date_of_record.last_month, is_active: true, aasm_state: :active)}
      let!(:qlek) { create(:qualifying_life_event_kind, is_active: false, aasm_state: :draft)}

      context "sucess" do

        before do
          active_qlek.expire!(TimeKeeper.date_of_record.yesterday)
        end

        it "should transition from draft to :active state" do
          expect(active_qlek.aasm_state).to eq :expired
        end

        it "should set end date" do
          expect(active_qlek.end_on).to eq TimeKeeper.date_of_record.yesterday
        end

        it "is_active set to false" do
          expect(qlek.is_active).to eq false
        end

        it "should create workflow_state_transition" do
          expect(active_qlek.workflow_state_transitions.first.from_state).to eq "active"
          expect(active_qlek.workflow_state_transitions.first.to_state).to eq "expired"
        end
      end

      context "failure" do

        it "can_be_expired? guard" do
          expect(qlek.may_expire?(TimeKeeper.date_of_record.next_day)).to eq false
        end

        it "should raise error for invalid transition" do
          expect { qlek.schedule_expiration!(TimeKeeper.date_of_record.next_day) }.to raise_error AASM::InvalidTransition
        end
      end
    end

    context "advance_date", dbclean: :after_each do

      let!(:active_qlek) { create(:qualifying_life_event_kind, start_on: TimeKeeper.date_of_record.last_month, is_active: true, aasm_state: :expire_pending)}
      let!(:qlek) { create(:qualifying_life_event_kind, is_active: false, aasm_state: :draft)}

      context "sucess" do

        before do
          active_qlek.advance_date!
        end

        it "should transition from draft to :active state" do
          expect(active_qlek.aasm_state).to eq :expired
        end

        it "is_active set to false" do
          expect(qlek.is_active).to eq false
        end

        it "should create workflow_state_transition" do
          expect(active_qlek.workflow_state_transitions.first.from_state).to eq "expire_pending"
          expect(active_qlek.workflow_state_transitions.first.to_state).to eq "expired"
        end
      end

      context "failure" do

        it "should return false" do
          expect(qlek.may_advance_date?).to eq false
        end

        it "should raise error for invalid transition" do
          expect { qlek.advance_date! }.to raise_error AASM::InvalidTransition
        end
      end
    end
  end

  context "advance_day" do
    let!(:past_expire_peding_qlek) { create(:qualifying_life_event_kind, start_on: TimeKeeper.date_of_record.last_month, end_on: TimeKeeper.date_of_record.yesterday, is_active: true, aasm_state: :expire_pending)}
    let!(:cur_expire_peding_qlek) { create(:qualifying_life_event_kind, start_on: TimeKeeper.date_of_record.last_month, end_on: TimeKeeper.date_of_record, is_active: true, aasm_state: :expire_pending)}

    before do
      QualifyingLifeEventKind.advance_day(TimeKeeper.date_of_record)
    end

    it "should expire eligble qleks" do
      past_expire_peding_qlek.reload
      expect(past_expire_peding_qlek.aasm_state).to eq :expired

      expect(past_expire_peding_qlek.workflow_state_transitions.first.from_state).to eq "expire_pending"
      expect(past_expire_peding_qlek.workflow_state_transitions.first.to_state).to eq "expired"
    end

    it "should not update not eligble qleks" do
      expect(cur_expire_peding_qlek.aasm_state).to eq :expire_pending
    end
  end
end
