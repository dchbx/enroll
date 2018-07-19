require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "components", "fix_employer_attestation")

describe FixEmployerAttestation, dbclean: :after_each do
  let(:given_task_name) { "fix_employer_attestation" }
  subject { FixEmployerAttestation.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update employer attestation for profiles" do

    let(:employer_organization)   { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)        { employer_organization.employer_profile }
    let(:site)                    { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:employer_attestation)   { FactoryGirl.build(:employer_attestation, aasm_state:'unsubmitted') }
    let!(:benefit_sponsorship)   { employer_profile.add_benefit_sponsorship }


    before(:each) do
      employer_profile.employer_attestation = employer_attestation
      benefit_sponsorship.save
      employer_profile.save
    end


    context "when employer is self_serve " do

      before do
        employer_profile.employer_attestation.employer_attestation_documents.create(title: "test", aasm_state:'submitted')
        employer_profile.save
      end

      it "should change effective on date" do
        expect(employer_attestation.aasm_state).to eq "unsubmitted"
        expect(employer_attestation.employer_attestation_documents.first.aasm_state).to eq "submitted"
        subject.migrate
        employer_profile.reload
        employer_attestation.reload
        expect(employer_attestation.aasm_state).to eq "submitted"
      end

    end

    context "when employer is conversion/mid_plan_year_conversion " do

      before do
        benefit_sponsorship.source_kind = :mid_plan_year_conversion
        benefit_sponsorship.save
      end

      it "should change effective on date" do
        expect(employer_attestation.aasm_state).to eq "unsubmitted"
        expect(employer_attestation.employer_attestation_documents).to eq []
        subject.migrate
        employer_profile.reload
        employer_attestation.reload
        expect(employer_attestation.aasm_state).to eq "approved"
      end
    end
  end
end
