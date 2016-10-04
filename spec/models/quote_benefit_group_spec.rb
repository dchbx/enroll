require 'rails_helper'

RSpec.describe QuoteBenefitGroup do
  
  let(:quote) {FactoryGirl.create(:quote, :with_household_and_members, start_on: TimeKeeper.date_of_record.beginning_of_month)}
  let(:quote_family) {FactoryGirl.create(:quote, :with_two_families, start_on: TimeKeeper.date_of_record.beginning_of_month)}
  let(:quote_next_year) {FactoryGirl.create(:quote, :with_household_and_members, start_on: TimeKeeper.date_of_record.beginning_of_month + 1.year)}

  context 'benefit group calculations', dbclean: :after_each do
  	before :each do
     @plan_silver = FactoryGirl.create(:plan, :with_premium_tables, metal_level: 'silver') 
     @plan_gold = FactoryGirl.create(:plan, :with_premium_tables, metal_level: 'gold')
     @dental_this_year = FactoryGirl.create(:plan, :shop_dental, :with_premium_tables)
     @dental_next_year = FactoryGirl.create(:plan, :shop_dental, :with_next_year_premium_tables)
     @plan_silver_next_year = FactoryGirl.create(:plan, :with_next_year_premium_tables)
  	 Caches::PlanDetails.load_record_cache!
  	 @current_year = TimeKeeper.date_of_record.year
  	 @next_year = @current_year + 1
  	end
    describe 'access to plans CACHED methods works' do
      it 'should have two current year health plans' do
      	expect(Plan.shop_plans('health', @current_year).count).to eq(2)
      end
      it 'should have one current year dental plans' do
        expect(Plan.shop_plans('dental', @current_year).count).to eq(1)
      end
      it 'should have one next year health plan' do
        expect(Plan.shop_plans('health', @next_year).count).to eq(1)
      end
      it 'should have one next year dental plan' do
        expect(Plan.shop_plans('dental', @next_year).count).to eq(1)
      end
    end

    describe 'flat_roster_for_premiums' do
      describe 'one household, one employee' do
        let(:bg) { quote.quote_benefit_groups.first}
        it 'should return one person' do
          expect(bg.flat_roster_for_premiums.values.first).to eq(29)   
        end
      end
      describe 'two families, spouse different age' do
        let(:bg) { quote_family.quote_benefit_groups.first}
        it 'should return four peeps' do
          expect(bg.flat_roster_for_premiums.values).to eq([29, 30, 29, 30])
        end
      end
    end
    describe 'premium calculations' do
      let(:roster_cost_all_plans_health) {bg.roster_cost_all_plans}
      let(:roster_cost_all_plans_dental) {bg.roster_cost_all_plans('dental')}
      let(:flat_roster) {bg.flat_roster_for_premiums}
      let(:roster_premium) {bg.roster_premium(@plan_silver, flat_roster)}
      let(:roster_premium_next_year) {bg.roster_premium(@plan_silver_next_year, flat_roster)}
      let(:silver_age_29) {Caches::PlanDetails.lookup_rate(@plan_silver.id, bg.quote.start_on, 29)}
      let(:silver_age_30) {Caches::PlanDetails.lookup_rate(@plan_silver.id, bg.quote.start_on, 30)}
      let(:silver_age_30_next_year) {Caches::PlanDetails.lookup_rate(@plan_silver_next_year.id, bg.quote.start_on, 30)}
      describe 'roster_premium for a specific plan' do
        describe 'one household, one employee (employee is 29)' do
          let(:bg) { quote.quote_benefit_groups.first}
          it 'should return one person' do
            expect(roster_premium.size).to eq(1)
            expect(roster_premium["employee"]).to eq(silver_age_29) 
          end
        end
        describe 'two families, spouse different age' do
          let(:bg) { quote_family.quote_benefit_groups.first}
          it 'should return two relationships' do
            expect(roster_premium.size).to eq(2)
            expect(roster_premium["employee"]).to eq(2*silver_age_29)
            expect(roster_premium["spouse"]).to eq(2*silver_age_30)   
          end
        end
        describe 'one household, one employee NEXT YEAR (same employee is 30)' do
          let(:bg) { quote_next_year.quote_benefit_groups.first}
          it 'should return one person' do
            expect(roster_premium_next_year.size).to eq(1)
            expect(roster_premium_next_year["employee"]).to eq(silver_age_30_next_year) 
          end
        end
      end
      describe 'one household, one employee' do
        let(:bg) { quote.quote_benefit_groups.first}
        it 'should reference all three health plans' do
          plans_cost_by_relationship = bg.roster_cost_all_plans
          expect(plans_cost_by_relationship.size).to eq(3)
          expect(plans_cost_by_relationship[@plan_silver.id.to_s]['employee']).to eq(silver_age_29) 
        end
      end
    end
  end
  context 'Roster cost for two plans' do
    describe 'Roster cost all plans, two families, employee & spouse' do  
      describe 'all plans,two families each has one employee, one spouse' do
        let(:bg) { quote_family.quote_benefit_groups.first}

        
        it 'should reference two health plans' do

          plan_gold = FactoryGirl.create(:plan, :with_premium_tables, metal_level: 'gold')
          plan_silver = FactoryGirl.create(:plan, :with_premium_tables, metal_level: 'silver')
          allow(Plan).to receive(:shop_plans).and_return([plan_gold, plan_silver])
          Caches::PlanDetails.load_record_cache!
          silver_age_29 = Caches::PlanDetails.lookup_rate(plan_silver.id, bg.quote.start_on, 29)
          silver_age_30 = Caches::PlanDetails.lookup_rate(plan_silver.id, bg.quote.start_on, 30)
          plans_cost_by_relationship = bg.roster_cost_all_plans
          expect(plans_cost_by_relationship[plan_silver.id.to_s]['employee']).to eq(2*silver_age_29) 
          expect(plans_cost_by_relationship[plan_silver.id.to_s]['spouse']).to eq(2*silver_age_30) 
        end
      end
    end
  end
end