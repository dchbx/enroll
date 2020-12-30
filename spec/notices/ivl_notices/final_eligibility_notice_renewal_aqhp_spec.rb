require 'rails_helper'
require 'csv'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  RSpec.describe "FinalEligibilityNoticeRenewalAqhp", :dbclean => :after_each do
    include_context 'setup benefit market with market catalogs and product packages'

    let!(:person3) { FactoryBot.create(:person, :with_consumer_role, hbx_id: "141890", first_name: "John", last_name: "Smith") }
    let!(:person4) { FactoryBot.create(:person, :with_consumer_role, hbx_id: "141891", first_name: "John", last_name: "Smith1") }

    let!(:family3) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person3) }
    let!(:family_member4) { FactoryBot.create(:family_member, family: family3, person: person4) }
    let!(:dependents) { family3.family_members }
    let!(:consumer_role) { person3.consumer_role }

    let(:effective_on) { TimeKeeper.date_of_record.beginning_of_year }
    let(:application_period) { effective_on..effective_on.end_of_year }

    let(:hbx_en_member3) do
      FactoryBot.build(
        :hbx_enrollment_member,
        eligibility_date: effective_on,
        coverage_start_on: effective_on,
        applicant_id: dependents[0].id
      )
    end

    let(:hbx_en_member4) do
      FactoryBot.build(
        :hbx_enrollment_member,
        eligibility_date: effective_on,
        coverage_start_on: effective_on,
        applicant_id: dependents[1].id
      )
    end

    let!(:issuer_profile) { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile) }

    let(:product) do
      FactoryBot.create(
        :benefit_markets_products_health_products_health_product,
        :with_renewal_product,
        :with_issuer_profile,
        benefit_market_kind: :aca_individual,
        kind: :health,
        assigned_site: site,
        service_area: service_area,
        renewal_service_area: renewal_service_area,
        csr_variant_id: '01',
        application_period: application_period
      )
    end

    let(:current_enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        family: family3,
        product: product,
        household: family3.active_household,
        coverage_kind: "health",
        effective_on: effective_on,
        kind: 'individual',
        hbx_enrollment_members: [hbx_en_member3, hbx_en_member4],
        aasm_state: 'coverage_selected'
      )
    end

    let(:renewal_product) do
      renewal_product = product.renewal_product
      renewal_product.issuer_profile_id = issuer_profile.id
      renewal_product.save!
      renewal_product
    end

    let(:renewing_enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        family: family3,
        product: renewal_product,
        household: family3.active_household,
        coverage_kind: "health",
        effective_on: effective_on.next_year,
        kind: 'individual',
        hbx_enrollment_members: [hbx_en_member3, hbx_en_member4],
        aasm_state: 'auto_renewing'
      )
    end

    let!(:input_file) { Rails.root.join("spec", "test_data", "notices", "ivl_fre_aqhp_test_data.csv") }

    describe "NoticeBuilder" do
      let(:data_elements) do
        [
          "consumer_role.notice_date",
          "consumer_role.first_name",
          "consumer_role.coverage_year",
          "consumer_role.renewing_enrollments",
          "consumer_role.uqhp_or_non_magi_medicaid_members_present?",
          "consumer_role.aqhp_or_non_magi_medicaid_members_present?",
          "consumer_role.renewing_health_enrollments_present?",
          "consumer_role.renewing_dental_enrollments",
          "consumer_role.renewing_health_enrollments",
          "consumer_role.same_health_product",
          "consumer_role.same_dental_product",
          "consumer_role.documents_needed",
          "consumer_role.ssa_unverified_individuals_present",
          "consumer_role.dhs_unverified_individuals_present",
          "consumer_role.immigration_unverified_individuals_present",
          "consumer_role.income_unverified_individuals_present",
          "consumer_role.residency_inconsistency_individuals_present",
          "consumer_role.mec_conflict_individuals_present",
          "consumer_role.american_indian_unverified_individuals_present"
        ]
      end

      let(:merge_model) { subject.construct_notice_object }
      let(:recipient)   { "Notifier::MergeDataModels::ConsumerRole" }
      let(:template)    { Notifier::Template.new(data_elements: data_elements) }

      let(:data_hash)  { build_data_hash }
      let(:members)    { data_hash.select { |_k,v| v.any? { |x| x['member_id'] == '141890' } }.first[1] }
      let(:subscriber) { members.detect{ |m| m["dependent"].casecmp('NO').zero? } }
      let(:dependents_array) { members.select{|m| m["dependent"].casecmp('YES').zero? } }

      let(:payload) do
        {
          "event_object_kind" => "ConsumerRole",
          "event_object_id" => consumer_role.id,
          "notice_params" => {
            "primary_member" => subscriber.to_hash,
            "dependents" => dependents_array.map(&:to_hash),
            "active_enrollment_ids" => [current_enrollment.hbx_id],
            "renewing_enrollment_ids" => [renewing_enrollment.hbx_id],
            "uqhp_event" => 'aqhp'
          }
        }
      end

      context "when notice event received" do

        subject { Notifier::NoticeKind.new(template: template, recipient: recipient, event_name: 'final_eligibility_notice_renewal') }

        before do
          allow(subject).to receive(:resource).and_return(consumer_role)
          allow(subject).to receive(:payload).and_return(payload)
        end

        it 'should retrun merge model' do
          expect(merge_model).to be_a(recipient.constantize)
        end

        it 'should return the date of the notice and coverage year' do
          expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%B %d, %Y')
          expect(merge_model.coverage_year).to eq TimeKeeper.date_of_record.next_year.year
        end

        it 'should return first name' do
          expect(merge_model.first_name).to eq person3.first_name
        end

        it 'should return a boolean if aqhp or uqhp' do
          expect(merge_model.aqhp_or_non_magi_medicaid_members_present?).to eq true
          expect(merge_model.uqhp_or_non_magi_medicaid_members_present?).to eq false
        end

        it 'should return renewing enrollments' do
          expect(merge_model.renewing_health_enrollments_present?).to eq true
          expect(merge_model.renewing_enrollments).to all(be_a(Notifier::MergeDataModels::Enrollment))
          expect(merge_model.renewing_health_enrollments).to all(be_a(Notifier::MergeDataModels::Enrollment))
          expect(merge_model.renewing_dental_enrollments).to eq []
        end

        it 'should return if it is a same product' do
          expect(merge_model.same_health_product).to eq true
          expect(merge_model.same_dental_product).to eq false
        end

        it "should return if documents needed" do
          expect(merge_model.documents_needed).to eq true
        end

        it "should return if any unverified individuals present or not" do
          expect(merge_model.ssa_unverified_individuals_present).to eq false
          expect(merge_model.dhs_unverified_individuals_present).to eq false
          expect(merge_model.immigration_unverified_individuals_present).to eq false
          expect(merge_model.income_unverified_individuals_present).to eq true
          expect(merge_model.residency_inconsistency_individuals_present).to eq false
          expect(merge_model.mec_conflict_individuals_present).to eq false
          expect(merge_model.american_indian_unverified_individuals_present).to eq false
        end
      end
    end
  end
end

private

def build_data_hash
  @data_hash = {}
  CSV.foreach(input_file,:headers => true).each do |d|
    if @data_hash[d["ic_number"]].present?
      @data_hash[d["ic_number"]] << d
    else
      @data_hash[d["ic_number"]] = [d]
    end
  end
  @data_hash
end
