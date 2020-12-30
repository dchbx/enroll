# frozen_string_literal: true

require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "extend_broker_application")

describe ExtendBrokerApplication, dbclean: :after_each do
  let(:given_task_name) { "extend_broker_application" }

  subject { ExtendBrokerApplication.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'extend broker application' do

    let(:site)                                  { FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key) }
    let!(:broker_organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
    let(:broker_agency_profile)                 { broker_organization.broker_agency_profile }
    let(:primary_broker_role)                   { broker_agency_profile.primary_broker_role }
    let!(:broker_person)                        { primary_broker_role.person }

    around do |example|
      ClimateControl.modify broker_npn: primary_broker_role.npn do
        example.run
      end
    end

    shared_examples_for "broker re-application" do |from_state, to_state|
      before :each do
        primary_broker_role.update_attributes!(aasm_state: from_state)
      end

      it "should transition from #{from_state} to #{to_state}" do
        subject.migrate
        primary_broker_role.reload
        expect(primary_broker_role.aasm_state).to eq to_state
      end
    end

    context "Broker Agency" do
      it_behaves_like 'broker re-application', 'denied', 'application_extended'
      it_behaves_like 'broker re-application', 'broker_agency_pending', 'application_extended'
    end
  end
end
