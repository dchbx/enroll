require 'rails_helper'
if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
require File.join(Rails.root, 'app', 'data_migrations', 'fix_citizen_status')

describe FixCitizenStatus, dbclean: :after_each do
  subject { FixCitizenStatus.new('fix_citizen_status', double(:current_scope => nil)) }
  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
  let(:person2) { FactoryGirl.create(:person, :with_consumer_role) }
  let(:person3) { FactoryGirl.create(:person, :with_consumer_role) }

  shared_examples_for 'fix_citizen_status' do |old_state, new_state, result|
    before do
      person.consumer_role.lawful_presence_determination.update_attributes!( citizen_status: old_state)
      person2.consumer_role.lawful_presence_determination.update_attributes!(citizen_status: new_state)
      person3.consumer_role.lawful_presence_determination.update_attributes!(citizen_status: new_state)
      allow(subject). to receive(:get_people).and_return([person])
      allow(person).to receive(:versions).and_return([person2, person3])
      subject.migrate
    end

    it "assigns #{result} as citizen status if old status: #{old_state} and current status: #{new_state}" do
      expect(person.consumer_role.lawful_presence_determination.citizen_status).to eq(result)
    end
  end

  context 'Citizenship status changed' do
    it_behaves_like 'fix_citizen_status', 'not_lawfully_present_in_us', 'alien_lawfully_present', 'alien_lawfully_present'
    it_behaves_like 'fix_citizen_status', 'non_native_not_lawfully_present_in_us', 'alien_lawfully_present', 'alien_lawfully_present'
  end
end
end
