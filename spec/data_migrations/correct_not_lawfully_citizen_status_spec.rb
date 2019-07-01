require 'rails_helper'
if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
require File.join(Rails.root, "app", "data_migrations", "correct_not_lawfully_citizen_status")

describe CorrectNotLawfullyCitizenStatus, dbclean: :after_each do
  subject { CorrectNotLawfullyCitizenStatus.new('correct_not_lawfully_citizen_status', double(:current_scope => nil)) }
  let(:person) { FactoryBot.create(:person, :with_consumer_role) }
  let(:person2) { FactoryBot.create(:person, :with_consumer_role) }
  let(:person3) { FactoryBot.create(:person, :with_consumer_role) }
  let(:verification_type) { FactoryBot.build(:verification_type, :type_name => "Immigration status")}
  let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
  let(:enrollment) {
    FactoryBot.create(:hbx_enrollment,
                       family: family,
                       household: family.active_household,
                       coverage_kind: 'health',
                       effective_on: TimeKeeper.date_of_record.next_month.beginning_of_month,
                       kind: 'individual',
                       submitted_at: TimeKeeper.date_of_record,
                       aasm_state: 'coverage_selected')
  }
  shared_examples_for 'correct_not_lawfully_citizen_status' do |old_state, new_state, result|
    before do
      person.consumer_role.lawful_presence_determination.update_attributes!( citizen_status: old_state)
      person2.consumer_role.lawful_presence_determination.update_attributes!(citizen_status: new_state)
      person3.consumer_role.lawful_presence_determination.update_attributes!(citizen_status: new_state)
      person.verification_types << verification_type
      allow(subject).to receive(:get_families).and_return([family])
      allow(subject).to receive(:get_enrollments).and_return([enrollment])
      allow(subject).to receive(:get_members).and_return([person])
      subject.migrate
    end
    it "assigns #{result} as citizen status if old status: #{old_state} and current status: #{new_state}" do
      expect(person.consumer_role.lawful_presence_determination.citizen_status).to eq(result)
    end
  end

  context 'Citizenship status changed' do
    it_behaves_like 'correct_not_lawfully_citizen_status', 'not_lawfully_present_in_us', 'alien_lawfully_present', 'alien_lawfully_present'
    it_behaves_like 'correct_not_lawfully_citizen_status', 'non_native_not_lawfully_present_in_us', 'alien_lawfully_present', 'alien_lawfully_present'
  end

end
end
