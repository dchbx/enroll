require 'rails_helper'

describe PlanSelection do

  subject { PlanSelection.new(hbx_enrollment, hbx_enrollment.plan) }

  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
  let(:person1) { FactoryGirl.create(:person, :with_consumer_role) }

  let(:family) {FactoryGirl.create(:family, :with_primary_family_member, :person => person)}
  let(:household) {FactoryGirl.create(:household, family: family)}

  let(:year){ TimeKeeper.date_of_record.year }
  let(:effective_on) { Date.new(year, 3, 1)}
  let(:previous_enrollment_status) { 'coverage_selected' }
  let(:terminated_on) { nil }
  let(:covered_individuals) { family.family_members }
  let(:newly_covered_individuals) { family.family_members }

  let(:plan) { 
    FactoryGirl.create(:plan, :with_premium_tables, market: 'individual', metal_level: 'silver', active_year: year, hios_id: "11111111122301-01", csr_variant_id: "01")
  }

  let!(:previous_coverage){  
    FactoryGirl.create(:hbx_enrollment,:with_enrollment_members, 
     enrollment_members: covered_individuals,
     household: family.latest_household,
     coverage_kind: "health",
     effective_on: effective_on.beginning_of_year,
     enrollment_kind: "open_enrollment",
     kind: "individual",
     consumer_role: person.consumer_role,
     plan: plan,
     aasm_state: previous_enrollment_status,
     terminated_on: terminated_on
     ) }

  let!(:hbx_enrollment) {
    FactoryGirl.create(:hbx_enrollment,:with_enrollment_members, 
     enrollment_members: newly_covered_individuals,
     household: family.latest_household,
     coverage_kind: "health",
     effective_on: effective_on,
     enrollment_kind: "open_enrollment",
     kind: "individual",
     consumer_role: person.consumer_role,
     plan: plan
     )
  }

  before do
    TimeKeeper.set_date_of_record_unprotected!(effective_on) 
  end

  describe '.existing_enrollment_for_covered_individuals' do

    context 'when active coverage present' do 
      it 'should return active coverage' do 
        expect(subject.existing_enrollment_for_covered_individuals).to eq previous_coverage
      end
    end

    context 'when previous coverage is terminated' do 
      context 'and there is a gap in coverage' do
       let(:previous_enrollment_status) { 'coverage_terminated' }
       let(:terminated_on) { effective_on - 10.days }

        it 'should not return terminated enrollment' do 
          expect(subject.existing_enrollment_for_covered_individuals).to be_nil
        end 
      end

      context 'and no gap in coverage' do 
        let(:previous_enrollment_status) { 'coverage_terminated' }
        let(:terminated_on) { effective_on.prev_day }

        it 'should return terminated enrollment' do 
          expect(subject.existing_enrollment_for_covered_individuals).to eq previous_coverage
        end
      end
    end

    context 'when member not coverged before' do 
      let(:family_member) { FactoryGirl.create(:family_member, family: family, person: person1)}
      let(:covered_individuals) { family.family_members.select{|fm| fm != family_member} }
      let(:newly_covered_individuals) { family_member.to_a }

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
        previous_eligibility_dates = Hash[previous_coverage.hbx_enrollment_members.collect {|hbx_em| [hash_key_creator(hbx_em), hbx_em.coverage_start_on]} ]
        new_eligibility_dates = Hash[hbx_enrollment.hbx_enrollment_members.collect {|hbx_em| [hash_key_creator(hbx_em), hbx_em.coverage_start_on]} ]
        new_eligibility_dates.each do |hbx_id,date|
          expect(previous_eligibility_dates[hbx_id]).to eq(date)
        end
      end
    end
  end
end