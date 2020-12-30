require 'rails_helper'
require File.join(File.dirname(__FILE__), "..", '..', 'app', 'data_migrations', 'reinstate_benefit_sponsorship')

RSpec.describe ReinstateBenefitSponsorship, dbclean: :after_each do

  let(:given_task_name) { 'reinstate_benefit_sponsorship' }
  subject { ReinstateBenefitSponsorship.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end
  describe 'reinstate benefit sponsorship' do
    let(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile) }

    it 'should change status of the benefit sponsorship from terminated to active' do
      benefit_sponsorship.update_attributes(aasm_state: :terminated)

      ClimateControl.modify id: benefit_sponsorship.id do
        subject.migrate
        benefit_sponsorship.reload
        expect(benefit_sponsorship.aasm_state).to eq :active
      end
    end
  end
end
