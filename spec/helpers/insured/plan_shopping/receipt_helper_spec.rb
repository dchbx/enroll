require "rails_helper"

RSpec.describe Insured::PlanShopping::ReceiptHelper, :type => :helper do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role, :with_family) }
  let!(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
  let(:family) { person.primary_family }
  let(:household) { family.active_household }
  let(:individual_plans) { FactoryGirl.create_list(:plan, 5, :with_premium_tables, market: 'individual') }

  describe "Carrier with payment options" do
    let(:carrier_profile) { FactoryGirl.create(:carrier_profile, legal_name:'Kaiser') }
    let(:plan) { FactoryGirl.create(:plan, carrier_profile:carrier_profile) }

    HbxEnrollment::Kinds.each do |market|
      context "#{market} market" do
        let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, :with_enrollment_members,
                                                   enrollment_members: family.family_members,
                                                   household: household,
                                                   plan: plan,
                                                   effective_on: TimeKeeper.date_of_record.beginning_of_year,
                                                   kind: market)}

        before :each do
          assign(:enrollment, hbx_enrollment)
        end
        it "returns #{market.in?(['individual', 'coverall'])} for #{market} + Kaiser" do
          expect(helper.show_pay_now?).to eq market.in?(['individual', 'coverall'])
        end
      end
    end
  end

  describe "Carrier with NO payment options" do
    let(:carrier_profile) { FactoryGirl.create(:carrier_profile, legal_name:'ANY OTHER') }
    let(:plan) { FactoryGirl.create(:plan, carrier_profile:carrier_profile) }
    let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, :with_enrollment_members,
                                               enrollment_members: family.family_members,
                                               household: household,
                                               plan: plan,
                                               effective_on: TimeKeeper.date_of_record.beginning_of_year,
                                               kind: 'individual')}
    before :each do
      assign(:enrollment, hbx_enrollment)
    end
    it "returns false for not Kaiser" do
      expect(helper.show_pay_now?).to eq false
    end
  end

  describe "Initial Kaiser Enrollment" do
    #payment_transaction_id
    #new_enrollment effective_of

  end
end