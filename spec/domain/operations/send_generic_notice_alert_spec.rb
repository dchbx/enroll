# frozen_string_literal: true

require "rails_helper"

module Operations
  RSpec.describe SendGenericNoticeAlert do

    subject do
      described_class.new.call(params)
    end

    let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key) }
    let(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_dc_employer_profile, site: site)}
    let(:employer_profile) {organization.employer_profile}

    let(:general_agency_person) { FactoryBot.create :person }
    let!(:general_agency_staff_role) { FactoryBot.create(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile.id, person: general_agency_person, is_primary: true)}
    let!(:general_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_general_agency_profile, organization: organization) }

    let(:broker_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile) }

    let(:consumer_person) {FactoryBot.create(:person, :with_consumer_role)}
    let(:employee_person) {FactoryBot.create(:person, :with_employee_role)}

    describe "not passing :resource" do

      let(:params) { { resource: nil }}
      let(:error_message) {{:message => ['Please find valid resource to send the alert message']}}

      it "fails" do
        expect(subject).not_to be_success
        expect(subject.failure).to eq error_message
      end
    end

    describe "passing consumer person as :resource" do

      let(:params) { { resource: consumer_person }}

      before do
        allow(consumer_person.consumer_role).to receive(:can_receive_electronic_communication?).and_return true
      end

      it "passes" do
        expect(subject).to be_success
      end
    end

    describe "passing employee person as :resource" do

      let(:params) { { resource: employee_person }}

      before do
        allow(employee_person.employee_roles.first).to receive(:can_receive_electronic_communication?).and_return true
      end

      it "passes" do
        expect(subject).to be_success
      end
    end

    describe "passing employer profile as :resource" do

      let(:params) { { resource: employer_profile }}

      before do
        allow(employer_profile).to receive(:can_receive_electronic_communication?).and_return true
      end

      it "passes" do
        expect(subject).to be_success
      end
    end

    describe "passing general agency profile as :resource" do

      let(:params) { { resource: general_agency_profile }}

      it "passes" do
        expect(subject).to be_success
      end
    end

<<<<<<< HEAD
=======
    describe "passing broker agency profile as :resource" do

      let(:params) { { resource: broker_agency_profile }}

      it "passes" do
        expect(subject).to be_success
      end
    end

>>>>>>> origin
  end
end
