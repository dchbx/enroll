require 'rails_helper'

RSpec.describe GeneralAgencyProfile, dbclean: :after_each do

  it { should validate_presence_of :market_kind }
  it { should delegate_method(:hbx_id).to :organization }
  it { should delegate_method(:legal_name).to :organization }
  it { should delegate_method(:dba).to :organization }
  it { should delegate_method(:fein).to :organization }
  it { should delegate_method(:is_active).to :organization }

  let(:organization) {FactoryGirl.create(:organization)}
  let(:market_kind) {"shop"}
  let(:bad_market_kind) {"commodities"}
  let(:market_kind_error_message) {"#{bad_market_kind} is not a valid market kind"}

  before :each do
    stub_const("GeneralAgencyProfile::MARKET_KINDS", ['shop', 'individual', 'both'])
  end

  describe ".new" do
    let(:valid_params) do
      {
        organization: organization,
        market_kind: market_kind,
        entity_kind: "s_corporation"
      }
    end

    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(GeneralAgencyProfile.new(**params).save).to be_falsey
      end
    end

    context "with individual disabled" do
      let(:bad_market_kind) { "individual" }
      before do
        stub_const("GeneralAgencyProfile::MARKET_KINDS", ['shop'])
      end
      it "returns an error if individual is market kind" do
        expect(
          GeneralAgencyProfile.create(**valid_params.merge(market_kind: bad_market_kind)).errors[:market_kind]
        ).to eq [market_kind_error_message]
      end
    end

    context "with no organization" do
      let(:params) {valid_params.except(:organization)}

      it "should raise" do
        expect{GeneralAgencyProfile.new(**params).save}.to raise_error(Mongoid::Errors::NoParent)
      end
    end

    context "with no market_kind" do
      let(:params) {valid_params.except(:market_kind)}

      it "should fail validation" do
        expect(GeneralAgencyProfile.create(**params).errors[:market_kind].any?).to be_truthy
      end
    end

    context "with invalid market_kind" do
      let(:params) {valid_params.deep_merge({market_kind: bad_market_kind})}

      it "should fail validation" do
        expect(GeneralAgencyProfile.create(**params).errors[:market_kind]).to eq [market_kind_error_message]
      end
    end

    context "with all valid arguments" do
      let(:params) {valid_params}
      let(:general_agency_profile) {GeneralAgencyProfile.new(**params)}

      it "should save" do
        expect(general_agency_profile.save!).to be_truthy
      end

      context "and it is saved" do
        before do
          general_agency_profile.save
        end

        it "should be findable by id" do
          expect(GeneralAgencyProfile.find(general_agency_profile.id).id.to_s).to eq general_agency_profile.id.to_s
        end

        context "and it has some employer profile clients" do
          let(:my_client_count)       { 3 }
          let(:general_agency_account) { GeneralAgencyAccount.new(general_agency_profile_id: general_agency_profile.id,
                                          start_on: TimeKeeper.date_of_record)}
          let!(:my_clients)           { FactoryGirl.create_list(:employer_profile, my_client_count,
                                          general_agency_accounts: [general_agency_account] )}

          it "should find all my active employer clients" do
            expect(general_agency_profile.employer_clients.to_a.size).to eq my_client_count
          end

          it "should return employer profile objects" do
            expect(general_agency_profile.employer_clients.first).to be_a EmployerProfile
          end
        end
      end
    end

    describe "all_by_broker_role" do
      let(:broker_role) { FactoryGirl.build :broker_role }
      let(:general_agency_profile_approved) { FactoryGirl.build :general_agency_profile , :aasm_state => "is_approved"}
      let(:general_agency_profile_applicant1) { FactoryGirl.build :general_agency_profile , :aasm_state => "is_applicant"}
      let(:general_agency_profile_applicant2) { FactoryGirl.build :general_agency_profile , :aasm_state => "is_applicant"}
      context "with approved general_agency_profiles" do
        before do
          allow(GeneralAgencyProfile).to receive(:all).and_return([general_agency_profile_approved,general_agency_profile_applicant1])
        end
        it "should only gett approved general agency profiles" do
          expect(GeneralAgencyProfile.all_by_broker_role(broker_role,:approved_only => true)).to eq [general_agency_profile_approved]
        end
      end
      context "with favorite general_agency_profile for broker_role" do
        before do
          allow(GeneralAgencyProfile).to receive(:all).and_return([general_agency_profile_approved,general_agency_profile_applicant1])
          allow(broker_role).to receive(:favorite_general_agencies).and_return([general_agency_profile_approved])
        end
        it "should only gett approved general agency profiles" do
          expect(GeneralAgencyProfile.all_by_broker_role(broker_role,:approved_only => true)).to eq [general_agency_profile_approved]
        end
      end
      context "without approved general_agency_profiles" do
        before do
          allow(GeneralAgencyProfile).to receive(:all).and_return([general_agency_profile_applicant1,general_agency_profile_applicant2])
        end
        it "should only gett approved general agency profiles" do
          expect(GeneralAgencyProfile.all_by_broker_role(broker_role,:approved_only => true)).to eq []
        end
      end
    end
  end

  describe "instance method", dbclean: :after_each do
    let(:general_agency_profile) { FactoryGirl.create(:general_agency_profile) }
    let(:employer_profile) { FactoryGirl.create(:employer_profile) }
    let(:person) { FactoryGirl.create(:person, :with_family) }
    let(:general_agency_staff_role) { FactoryGirl.create(:general_agency_staff_role, person:person, general_agency_profile_id: general_agency_profile.id) }

    it "current_state" do
      general_agency_profile.aasm_state = "is_approved"
      expect(general_agency_profile.current_state).to eq "Is Approved"
    end

    it "legal_name" do
      expect(general_agency_profile.legal_name).to eq general_agency_profile.organization.legal_name
    end

    it "linked_employees" do
      allow(EmployerProfile).to receive(:find_by_general_agency_profile).and_return [employer_profile]
      allow(Person).to receive(:where).and_return [person]
      expect(general_agency_profile.linked_employees).to eq [person]
    end

    it "families" do
      allow(EmployerProfile).to receive(:find_by_general_agency_profile).and_return [employer_profile]
      allow(Person).to receive(:where).and_return [person]
      expect(general_agency_profile.families).to eq [person.primary_family]
    end

    context "for general_agency_staff_role" do
      before :each do
        general_agency_staff_role
      end

      it "general_agency_staff_roles" do
        expect(general_agency_profile.general_agency_staff_roles).to eq [general_agency_staff_role]
      end

      it "primary_staff" do
        expect(general_agency_profile.primary_staff).to eq general_agency_staff_role
      end

      it "current_staff_state" do
        expect(general_agency_profile.current_staff_state).to eq general_agency_staff_role.current_state
      end
    end
  end

  describe "class method" do
    let(:general_agency_profile) { FactoryGirl.create(:general_agency_profile) }
    let(:broker_role) { FactoryGirl.create(:broker_role) }

    context "all_by_broker_role" do
      before :each do
        10.times { FactoryGirl.create(:general_agency_profile) }
        broker_role.favorite_general_agencies.create(general_agency_profile_id: general_agency_profile.id)
      end

      it "should return general_agency_profile that sort by favorite_general_agencies" do
        sorted_general_agency_profiles = GeneralAgencyProfile.all.sort {|ga| [general_agency_profile.id].include?(ga.id) ? 0:1 }
        expect(GeneralAgencyProfile.all_by_broker_role(broker_role)).to eq sorted_general_agency_profiles
      end
    end

    context "filter_by" do
      let(:ga1) { FactoryGirl.create(:general_agency_profile, aasm_state: 'is_applicant') }
      let(:ga2) { FactoryGirl.create(:general_agency_profile, aasm_state: 'is_approved') }
      let(:ga3) { FactoryGirl.create(:general_agency_profile, aasm_state: 'is_suspended') }
      before :each do
        ga1
        ga2
        ga3
      end

      it "should get all general_agency_profile" do
        expect(GeneralAgencyProfile.filter_by('all')).to eq GeneralAgencyProfile.all
      end

      it "should get applicant ga without params" do
        expect(GeneralAgencyProfile.filter_by()).to eq [ga1]
      end

      it "should get approved ga" do
        expect(GeneralAgencyProfile.filter_by('is_approved')).to eq [ga2]
      end

      it "should get suspend ga "do
        expect(GeneralAgencyProfile.filter_by('is_suspended')).to eq [ga3]
      end

      it "should get blank" do
        expect(GeneralAgencyProfile.filter_by('other')).to eq []
      end
    end
  end

  if general_agency_enabled?
    describe "general agency notice trigger", type: :model, dbclean: :after_all do
      let(:general_agency_profile) { FactoryGirl.create(:general_agency_profile) }
      let(:employer_profile) { FactoryGirl.create(:employer_profile, general_agency_profile: general_agency_profile) }

      it "should trigger general_agency_hired_notice job in queue" do
        ActiveJob::Base.queue_adapter = :test
        ActiveJob::Base.queue_adapter.enqueued_jobs = []
        general_agency_profile.general_agency_hired_notice(employer_profile)
        queued_job = ActiveJob::Base.queue_adapter.enqueued_jobs.find do |job_info|
          job_info[:job] == ShopNoticesNotifierJob
        end

          expect(queued_job[:args]).not_to be_empty
          expect(queued_job[:args].include?('general_agency_hired_notice')).to be_truthy
          expect(queued_job[:args].include?("#{general_agency_profile.id.to_s}")).to be_truthy
          expect(queued_job[:args].third["employer_profile_id"]).to eq employer_profile.id.to_s
      end
    end
  end
end
