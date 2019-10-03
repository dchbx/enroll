require 'rails_helper'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  describe PlanSelection, dbclean: :after_each do

    subject {PlanSelection.new(hbx_enrollment, hbx_enrollment.product)}

    let(:person) do
      person = FactoryBot.create(:person, :with_active_consumer_role, :with_consumer_role)
      person.consumer_role.aasm_state = 'verification_outstanding'
      person
    end
    let(:person1) do
      person = FactoryBot.create(:person, :with_active_consumer_role, :with_consumer_role)
      person.consumer_role.aasm_state = 'verification_outstanding'
      person
    end

    let(:family) {FactoryBot.create(:family, :with_primary_family_member, :person => person)}
    let(:household) {FactoryBot.create(:household, family: family)}

    let(:year) {TimeKeeper.date_of_record.year}
    let(:effective_on) {Date.new(year, 3, 1)}
    let(:previous_enrollment_status) {'coverage_selected'}
    let(:terminated_on) {nil}
    let(:covered_individuals) {family.family_members}
    let(:newly_covered_individuals) {family.family_members}

    let(:start_on) {TimeKeeper.date_of_record.beginning_of_month}

    let(:qualifying_life_event_kind) {FactoryBot.create(:qualifying_life_event_kind)}
    let(:special_enrollment_period) do
      special_enrollment = person.primary_family.special_enrollment_periods.build({effective_on_kind: 'first_of_month'})
      special_enrollment.qualifying_life_event_kind = qualifying_life_event_kind
      special_enrollment.start_on = TimeKeeper.date_of_record.prev_day
      special_enrollment.end_on = TimeKeeper.date_of_record + 30.days
      special_enrollment.save
      special_enrollment
    end

    let(:product) do
      FactoryBot.create(:benefit_markets_products_health_products_health_product,
                        hios_id: '11111111122301-01',
                        csr_variant_id: '01',
                        metal_level_kind: :silver,
                        benefit_market_kind: :aca_individual,
                        application_period: Date.new(year, 1, 1)..Date.new(year, 12, 31))
    end


    let!(:previous_coverage) do
      FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                        enrollment_members: covered_individuals,
                        family: family,
                        household: family.latest_household,
                        coverage_kind: 'health',
                        effective_on: effective_on.beginning_of_year,
                        enrollment_kind: 'open_enrollment',
                        kind: 'individual',
                        consumer_role: person.consumer_role,
                        product: product,
                        aasm_state: previous_enrollment_status,
                        terminated_on: terminated_on)
    end

    let!(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                        enrollment_members: newly_covered_individuals,
                        family: family,
                        household: family.latest_household,
                        coverage_kind: 'health',
                        effective_on: effective_on,
                        enrollment_kind: 'open_enrollment',
                        kind: 'individual',
                        consumer_role: person.consumer_role,
                        product: product)
    end

    describe '.verify_and_set_member_coverage_start_dates' do

      context 'When previous continuous coverage is present' do
        it 'should set predecessor_enrollment_id' do
          subject.verify_and_set_member_coverage_start_dates
          expect(hbx_enrollment.predecessor_enrollment_id).to eq previous_coverage.id
        end
      end

      context 'When previous continuous coverage is not present' do
        let(:previous_enrollment_status) {'coverage_terminated'}
        let(:terminated_on) {effective_on - 10.days}

        it 'should not set predecessor_enrollment_id' do
          subject.verify_and_set_member_coverage_start_dates
          expect(hbx_enrollment.predecessor_enrollment_id).to eq nil
        end
      end
    end

    describe '.existing_enrollment_for_covered_individuals' do

      before do
        TimeKeeper.set_date_of_record_unprotected!(effective_on)
      end

      after do
        TimeKeeper.set_date_of_record_unprotected!(Time.zone.today)
      end

      context 'when active coverage present' do
        it 'should return active coverage' do
          expect(subject.existing_enrollment_for_covered_individuals).to eq previous_coverage
        end
      end

      context 'when previous coverage is terminated' do
        context 'and there is a gap in coverage' do
          let(:previous_enrollment_status) {'coverage_terminated'}
          let(:terminated_on) {effective_on - 10.days}

          it 'should not return terminated enrollment' do
            expect(subject.existing_enrollment_for_covered_individuals).to be_nil
          end
        end

        context 'and no gap in coverage' do
          let(:previous_enrollment_status) {'coverage_terminated'}
          let(:terminated_on) {effective_on.prev_day}

          it 'should return terminated enrollment' do
            expect(subject.existing_enrollment_for_covered_individuals).to eq previous_coverage
          end
        end
      end

      context 'when member not coverged before' do
        let(:family_member) {FactoryBot.create(:family_member, family: family, person: person1)}
        let(:covered_individuals) {family.family_members.reject {|fm| fm == family_member}}
        let(:newly_covered_individuals) {family_member.to_a}

        it 'should return nothing' do
          expect(subject.existing_enrollment_for_covered_individuals).to be_nil
        end
      end
    end

    describe '.set_enrollment_member_coverage_start_dates' do
      context 'when a new enrollment has a previous enrollment' do
        def hash_key_creator(hbx_enrollment_member)
          hbx_enrollment_member.person.hbx_id
        end

        it 'should set eligibility dates to that of the previous enrollment' do
          subject.set_enrollment_member_coverage_start_dates
          previous_eligibility_dates = Hash[previous_coverage.hbx_enrollment_members.collect {|hbx_em| [hash_key_creator(hbx_em), hbx_em.coverage_start_on]}]
          new_eligibility_dates = Hash[hbx_enrollment.hbx_enrollment_members.collect {|hbx_em| [hash_key_creator(hbx_em), hbx_em.coverage_start_on]}]
          new_eligibility_dates.each do |hbx_id, date|
            expect(previous_eligibility_dates[hbx_id]).to eq(date)
          end
        end
      end
    end

    describe '.select_plan_and_deactivate_other_enrollments' do

      context 'hbx_enrollment aasm state check' do
        it 'should set is_any_enrollment_member_outstanding to true if any verification outstanding people' do
          subject.hbx_enrollment.hbx_enrollment_members.flat_map(&:person).flat_map(&:consumer_role).first.update_attribute("aasm_state","verification_outstanding")
          subject.hbx_enrollment.update_attributes(aasm_state: 'shopping')
          subject.select_plan_and_deactivate_other_enrollments(nil, 'individual')
          expect(subject.hbx_enrollment.aasm_state).to eq('coverage_selected')
          expect(subject.hbx_enrollment.is_any_enrollment_member_outstanding).to eq true
        end

        it 'should set is_any_enrollment_member_outstanding to false if no verification outstanding people' do
          subject.hbx_enrollment.hbx_enrollment_members.flat_map(&:person).flat_map(&:consumer_role).first.update_attribute("aasm_state","verified")
          subject.hbx_enrollment.update_attributes(aasm_state: 'shopping')
          subject.select_plan_and_deactivate_other_enrollments(nil, 'individual')
          expect(subject.hbx_enrollment.aasm_state).to eq('coverage_selected')
          expect(subject.hbx_enrollment.is_any_enrollment_member_outstanding).to eq false
        end
      end
    end
  end
end
