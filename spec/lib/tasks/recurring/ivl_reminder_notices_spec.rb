require 'rails_helper'
require 'rake'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
describe 'recurring:ivl_reminder_notices', :dbclean => :after_each do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role)}
  let!(:family) {FactoryGirl.create(:family, :with_primary_family_member, person: person, e_case_id: nil)}
  let!(:hbx_enrollment) {FactoryGirl.create(:hbx_enrollment, household: family.households.first, kind: "individual", aasm_state: "enrolled_contingent", applied_aptc_amount: 0.0)}
  let!(:hbx_enrollment_member) {FactoryGirl.create(:hbx_enrollment_member,hbx_enrollment: hbx_enrollment, applicant_id: family.family_members.first.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record.prev_month )}

  before do
    load File.expand_path("#{Rails.root}/lib/tasks/recurring/ivl_reminder_notices.rake", __FILE__)
    Rake::Task.define_task(:environment)
  end

  context "for unassisted individuals", :dbclean => :after_each do

    it "should send reminder notice when due date is great than or eq to 30 days" do
      special_verification = SpecialVerification.new(due_date: TimeKeeper.date_of_record+30.days, verification_type: "Social Security Number", type: "notice")
      person.consumer_role.special_verifications << special_verification
      person.consumer_role.save!
      expect(IvlNoticesNotifierJob).to receive(:perform_later)
      Rake::Task["recurring:ivl_reminder_notices"].invoke
    end

    it "should NOT send reminder notice when due date is less than 30 days" do
      special_verification = SpecialVerification.new(due_date: TimeKeeper.date_of_record+1.days, verification_type: "Citizenship", type: "notice")
      person.consumer_role.special_verifications << special_verification
      person.consumer_role.save!
      expect(IvlNoticesNotifierJob).not_to receive(:perform_later)
      Rake::Task["recurring:ivl_reminder_notices"].invoke
    end
  end

  context "for individuals who have filled in application through curam", :dbclean => :after_each do

    it "should NOT send reminder notice" do
      family.update_attributes!(:e_case_id => "someecaseid")
      special_verification = SpecialVerification.new(due_date: TimeKeeper.date_of_record+30.days, verification_type: "Citizenship", type: "notice")
      person.consumer_role.special_verifications << special_verification
      person.consumer_role.save!
      expect(IvlNoticesNotifierJob).not_to receive(:perform_later)
      Rake::Task["recurring:ivl_reminder_notices"].invoke
    end
  end
  context "for assisted individuals", :dbclean => :after_each do

    it "should NOT send reminder notice" do
      hbx_enrollment.update_attributes!(:applied_aptc_amount => 354)
      special_verification = SpecialVerification.new(due_date: TimeKeeper.date_of_record+30.days, verification_type: "Citizenship", type: "notice")
      person.consumer_role.special_verifications << special_verification
      person.consumer_role.save!
      expect(IvlNoticesNotifierJob).not_to receive(:perform_later)
      Rake::Task["recurring:ivl_reminder_notices"].invoke
    end
  end
end
end
