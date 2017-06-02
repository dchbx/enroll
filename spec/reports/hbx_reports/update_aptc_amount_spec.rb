require "rails_helper"
require File.join(Rails.root, "app", "reports", "hbx_reports", "update_aptc_amount")
describe UpdateAptcAmount do
  let(:given_task_name) { "update_aptc_amount" }
  let(:person1) {FactoryGirl.create(:person,
                                    :with_consumer_role,
                                    first_name: "F_name1",
                                    last_name:"L_name1")}
  let(:hbx_enrollment_member1){ FactoryGirl.build(:hbx_enrollment_member, applicant_id: family1.family_members.first.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
  let(:family1) { FactoryGirl.create(:family, :with_primary_family_member, :person => person1)}
  let(:plan){FactoryGirl.create(:plan, :ehb => 0.9945)}
  let(:hbx_enrollment1) { FactoryGirl.create(:hbx_enrollment,
                                             household: family1.active_household,
                                             hbx_enrollment_members: [hbx_enrollment_member1],
                                             effective_on: Date.parse("2017-1-1"),
                                             plan: plan,
                                             applied_aptc_amount: 550.98
                                             )}
  subject {UpdateAptcAmount.new(given_task_name, double(:current_scope => nil))}
  describe "correct data input" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
    it "should update aptc amount if plan exists and ehb value is greater than 0" do
    	hbx_enrollment1.reload
    	subject.migrate
    	hbx_enrollment1.reload
    	expect(hbx_enrollment1.applied_aptc_amount.to_f).to eql ((hbx_enrollment1.total_premium * hbx_enrollment1.plan.ehb).round(2))
    end
    it "should do nothing if applied_aptc_amount is equal or less than ehb_premium" do
      expect(hbx_enrollment1.applied_aptc_amount.to_f).to eql (550.98)
    end
  end
end
