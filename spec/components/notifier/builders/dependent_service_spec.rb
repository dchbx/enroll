# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"

class FakeConsumerRoleHelper
  include Notifier::ConsumerRoleHelper
end

RSpec.describe 'Components::Notifier::Builders::DependentService', :dbclean => :after_each do

  describe "A new model instance" do

    context 'PRE notice' do
      let(:payload) do
        file = Rails.root.join("spec", "test_data", "notices", "proj_elig_report_aqhp_2019_test_data.csv")
        csv = CSV.open(file, "r", :headers => true)
        data = csv.to_a

        {"consumer_role_id" => "5c61bf485f326d4e4f00000c",
         "event_object_kind" => "ConsumerRole",
         "event_object_id" => "5bcdec94eab5e76691000cec",
         "notice_params" => {"dependents" => data.select{ |m| m["dependent"].casecmp('YES').zero? }.map(&:to_hash),

                             "primary_member" => data.detect{ |m| m["dependent"].casecmp('NO').zero? }.to_hash}}
      end

      let!(:person) { FactoryBot.create(:person, :with_consumer_role, hbx_id: "3117597607a14ef085f9220f4d189356", first_name: "Samules", last_name: "Park") }

      let!(:family){ FactoryBot.create(:family, :with_primary_family_member, person: person) }

      let(:member) do
        payload['notice_params']['dependents'].select { |m| m['member_id'] == person.hbx_id }.first
      end

      let(:aqhp_dependent) { ::Notifier::Services::DependentService.new(false, member, nil) }

      context "Model attributes" do
        it "should have first name from payload" do
          expect(aqhp_dependent.first_name).to eq(member["first_name"])
        end

        it "should have last name from payload" do
          expect(aqhp_dependent.last_name).to eq(member["last_name"])
        end

        it "should have member age from payload" do
          # 2019 matches the year in the file name
          member_dob = Date.strptime(member['dob'], '%m/%d/%Y')
          expect(aqhp_dependent.age).to eq(((TimeKeeper.date_of_record - member_dob) / 365.25).floor)
        end
      end
    end

    describe 'IVL FEL notice' do
      include_context 'setup benefit market with market catalogs and product packages'

      let(:file_name) { Rails.root.join("spec", "test_data", "notices", "ivl_fel_aqhp_test_data.csv") }

      let(:data) do
        data_hash = {}
        CSV.foreach(file_name,:headers => true).each do |d|
          if data_hash[d["ic_number"]].present?
            data_hash[d["ic_number"]].collect{|r| r['member_id']}
            data_hash[d["ic_number"]] << d
          else
            data_hash[d["ic_number"]] = [d]
          end
        end

        data_hash.values[0].map(&:to_hash)
      end

      let(:payload3) do
        {
          "consumer_role_id" => consumer_role.id,
          "event_object_kind" => "ConsumerRole",
          "event_object_id" => consumer_role.id,
          "notice_params" => {
            "dependents" => data,
            "active_enrollment_ids" => [current_enrollment.hbx_id],
            "renewing_enrollment_ids" => [renewing_enrollment.hbx_id]
          }
        }
      end
      let!(:person3) { FactoryBot.create(:person, :with_consumer_role, hbx_id: "141890", first_name: "John", last_name: "Smith") }
      let!(:person4) { FactoryBot.create(:person, :with_consumer_role, hbx_id: "141891", first_name: "John", last_name: "Smith1") }
      let!(:family_member4) { FactoryBot.create(:family_member, family: family3, person: person4) }
      let(:consumer_role) { person3.consumer_role }

      let!(:family3) { FactoryBot.create(:family, :with_primary_family_member, person: person3) }

      let(:dependents) { family3.family_members }

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

      let(:issuer_profile) { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile) }

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

      let(:renewal_product) { product.renewal_product }

      let!(:current_enrollment) do
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

      let!(:renewing_enrollment) do
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

      let!(:notice_builder) do
        builder = Notifier::Builders::ConsumerRole.new
        builder.payload = payload3
        builder.consumer_role = person3.consumer_role
        builder.dependents
        builder
      end

      let(:fel_dependent) { notice_builder.merge_model.dependents[0] }

      let(:fake_class) { FakeConsumerRoleHelper.new }

      context 'load dependent information' do

        it 'should load income information' do
          expect(fel_dependent.expected_income_for_coverage_year).to eq fake_class.format_currency(data[0]['actual_income'])
        end

        it 'should load mec information' do
          expect(fel_dependent.mec).to eq fake_class.check_format(data[0]['mec'])
        end

        it 'should load indian_conflict information' do
          expect(fel_dependent.indian_conflict).to eq fake_class.check_format(data[0]['indian'])
        end

        it 'should load is_medicaid_chip_eligible information' do
          expect(fel_dependent.is_medicaid_chip_eligible).to eq fake_class.check_format(data[0]['magi_medicaid'])
        end

        it 'should load non_magi_medicaid information' do
          expect(fel_dependent.is_non_magi_medicaid_eligible).to eq fake_class.check_format(data[0]['non_magi_medicaid'])
        end

        it 'should load medicaid_monthly_income_limit information' do
          expect(fel_dependent.magi_medicaid_monthly_income_limit).to eq fake_class.format_currency(data[0]['medicaid_monthly_income_limit'])
        end

        it 'should load magi_as_fpl information' do
          expect(fel_dependent.magi_as_percentage_of_fpl).to eq data[0]['magi_as_fpl'].to_i
        end

        it 'should load has_access_to_affordable_coverage information' do
          expect(fel_dependent.has_access_to_affordable_coverage).to eq fake_class.check_format(data[0]['mec'])
        end
      end
    end

  end
end
