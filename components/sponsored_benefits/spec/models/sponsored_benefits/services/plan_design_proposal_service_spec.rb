RSpec.describe SponsoredBenefits::Services::PlanDesignProposalService, type: :model, dbclean: :after_each do

  let(:subject) { SponsoredBenefits::Services::PlanDesignProposalService.new(
    kind: benefit_kind,
    proposal: proposal
  )}

  let(:organization) { FactoryBot.create(:sponsored_benefits_plan_design_organization, :with_profile)}
  let(:proposal) { organization.plan_design_proposals.first }
  let(:benefit_kind) { "health" }
  let(:profile) { proposal.profile }
  let(:sponsorship) { profile.benefit_sponsorships.first }
  let(:application) { FactoryBot.create(:plan_design_benefit_application, benefit_sponsorship: sponsorship)}

  before do
    DatabaseCleaner.clean
    allow_any_instance_of(SponsoredBenefits::Organizations::PlanDesignOrganization).to receive(:is_renewing_employer?).and_return(false)
  end

  describe "model attributes", dbclean: :after_each do

    it "should initialize benefit kind" do
      expect(subject.kind).to eq benefit_kind
    end

    it "should initialize proposal" do
      expect(subject.proposal).to eq proposal
    end
  end

  describe "#ensure_health_benefits", dbclean: :after_each do

    before do
      application
      subject.ensure_health_benefits
      @benefit_group = application.benefit_groups.first
    end

    it "should build a benefit group" do
      expect(application.benefit_groups.size).to eq 1
    end

    it "should not persist benefit group" do
      expect(@benefit_group.persisted?).to eq false
    end

    it "should build relationship benefits" do
      expect(@benefit_group.relationship_benefits.present?).to eq true
    end

    it "should build composite tier contributions" do
      # currently we do not have composite_tier_contributions(DC BQT) model we should only
      # Build these only when benefit_group plan_option_kind is solesource
      expect(@benefit_group.composite_tier_contributions.present?).to eq true if @benefit_group.sole_source?
    end

    it "should not build composite tier contributions if it is not sole source" do
    end
  end

  describe "#ensure_dental_benefits" do

    let(:benefit_kind) { "dental" }
    let(:application) { FactoryBot.create(:plan_design_benefit_application, :with_benefit_group, benefit_sponsorship: sponsorship) }

    before do
      application
      subject.ensure_dental_benefits
    end

    it "should build dental relationship benefits" do
      benefit_group = application.benefit_groups.first
      expect(benefit_group.dental_relationship_benefits.present?).to eq true
    end
  end

  describe "save benefits" do

    let(:relationship_benefits_attributes) {
      {
        "0" => {:relationship => "employee", :premium_pct =>"65", :offered => "true"},
        "1" => {:relationship => "spouse", :premium_pct =>"65", :offered => "true"},
        "2" => {:relationship => "domestic_partner", :premium_pct =>"65", :offered => "true"},
        "3" => {:relationship => "child_under_26", :premium_pct =>"70", :offered => "true"},
        "4" => {:relationship => "child_26_and_over", :premium_pct =>"0", :offered => "false"}
      }
    }

    let(:health_attributes) {
      {
        :plan_option_kind => health_plan_option_kind,
        :relationship_benefits_attributes => relationship_benefits_attributes
      }
    }
    let(:health_plan_option_kind) { "single_issuer" }

    let(:benefit_group) { application.benefit_groups.first }

    context "#save_health_benefits" do

      before do
        allow(organization).to receive_message_chain(:broker_agency_profile, :legal_name).and_return("Broker Profile")
        application
        subject.save_health_benefits(health_attributes)
      end

      it "should have plan_option_kind being set" do
        expect(benefit_group.plan_option_kind).to eq health_plan_option_kind
      end

      it "should have relationship_benefits being set" do
        employee_benefits = benefit_group.relationship_benefits.where(:relationship => "employee").first
        expect(employee_benefits.premium_pct).to eq 65.0
      end
    end

    context "#save_dental_benefits" do
      let(:dental_plan_option_kind) { "single_plan" }
      let(:dental_attributes) {
        {
          :plan_option_kind => dental_plan_option_kind,
          :relationship_benefits_attributes => relationship_benefits_attributes
        }
      }
      let(:benefit_kind) { "dental" }

      before do
        application
        allow(organization).to receive_message_chain(:broker_agency_profile, :legal_name).and_return "LegalName"
        subject.save_health_benefits(health_attributes)
        subject.save_dental_benefits(dental_attributes)
      end

      it "should have dental_plan_option_kind being set" do
        expect(benefit_group.dental_plan_option_kind).to eq dental_plan_option_kind
      end

      it "should have dental_relationship_benefits being set" do
        employee_dental_benefits = benefit_group.dental_relationship_benefits.where(:relationship => "employee").first
        expect(employee_dental_benefits.premium_pct).to eq 65.0
      end
    end
  end
end
