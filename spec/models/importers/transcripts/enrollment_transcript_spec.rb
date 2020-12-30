# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Importers::Transcripts::EnrollmentTranscript, type: :model, dbclean: :after_each do

  context ".process" do

    let!(:spouse) { FactoryBot.create(:person) }
    let!(:child1) { FactoryBot.create(:person) }
    let!(:child2) { FactoryBot.create(:person) }

    let!(:person) do
      p = FactoryBot.build(:person)
      p.person_relationships.build(relative: spouse, kind: "spouse")
      p.person_relationships.build(relative: child1, kind: "child")
      p.person_relationships.build(relative: child2, kind: "child")
      p.save
      p
    end

    let(:source_effective_on) { Date.new(TimeKeeper.date_of_record.year, 1, 1) }
    let(:other_effective_on) { Date.new(TimeKeeper.date_of_record.year, 3, 1) }

    let(:other_plan) { FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual) }
    let(:source_plan) { FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual) }

    let(:other_family) do
      family = Family.new({
                            hbx_assigned_id: '24112',
                            e_case_id: "6754632"
                          })
      family.family_members.build(is_primary_applicant: true, person: person)
      family
    end

    let(:dependent1) do
      other_family.family_members.build(is_primary_applicant: false, person: spouse)
    end

    let(:dependent2) do
      other_family.family_members.build(is_primary_applicant: false, person: child1)
    end

    let(:other_enrollment) do
      enrollment = other_family.active_household.hbx_enrollments.build({hbx_id: '1000006', kind: 'individual', product: other_plan, effective_on: other_effective_on, terminated_on: other_effective_on.end_of_month})
      enrollment.hbx_enrollment_members.build({applicant_id: other_family.primary_applicant.id, is_subscriber: true, coverage_start_on: other_effective_on})
      enrollment.hbx_enrollment_members.build({applicant_id: dependent1.id, is_subscriber: false, coverage_start_on: other_effective_on})
      enrollment.hbx_enrollment_members.build({applicant_id: dependent2.id, is_subscriber: false, coverage_start_on: other_effective_on})
      enrollment.family = other_family
      enrollment
    end

    let!(:source_family) do
      family = Family.create({hbx_assigned_id: '25112', e_case_id: "6754632"})
      family.family_members.build(is_primary_applicant: true, person: person)
      family.family_members.build(is_primary_applicant: false, person: spouse)
      family.family_members.build(is_primary_applicant: false, person: child1)
      family.family_members.build(is_primary_applicant: false, person: child2)
      family.save
      family
    end

    let(:primary) { source_family.primary_applicant }
    let(:dependent) { source_family.family_members.detect { |fm| !fm.is_primary_applicant } }

    let(:factory) { Transcripts::EnrollmentTranscript.new }
    let(:importer) { Importers::Transcripts::EnrollmentTranscript.new }

    context 'hbx_enrollment_members' do

      context '.add' do

        let(:compare) do
          {
            :base => {},
            :plan => {"update" => {}},
            :hbx_enrollment_members => {
              "update" => {"hbx_id:#{primary.hbx_id}" => {}},
              "add" => {"hbx_id" => {"hbx_id" => spouse.hbx_id, "is_subscriber" => false, "coverage_start_on" => Date.new(TimeKeeper.date_of_record.year, 1, 1), "coverage_end_on" => Date.new(TimeKeeper.date_of_record.year, 1, 31)}}
            }
          }
        end

        let!(:source_enrollment_1) do
          enrollment = source_family.active_household.hbx_enrollments.build({hbx_id: '1000001', kind: 'individual', product: source_plan, effective_on: source_effective_on, aasm_state: 'coverage_selected'})
          enrollment.hbx_enrollment_members.build({applicant_id: primary.id, is_subscriber: true, coverage_start_on: source_effective_on, eligibility_date: source_effective_on})
          enrollment.family = source_family
          enrollment.save
          enrollment
        end

        let(:transcript) do
          {
            :source => {'_id' => source_enrollment_1.id},
            :compare => compare,
            :other => nil
          }
        end

        let(:other_enrollment) do
          enrollment = other_family.active_household.hbx_enrollments.build({hbx_id: '1000006', kind: 'individual', product: other_plan, effective_on: other_effective_on})
          enrollment.hbx_enrollment_members.build({applicant_id: other_family.primary_applicant.id, is_subscriber: true, coverage_start_on: other_effective_on})
          enrollment.hbx_enrollment_members.build({applicant_id: dependent1.id, is_subscriber: false, coverage_start_on: other_effective_on})
          enrollment.hbx_enrollment_members.build({applicant_id: dependent2.id, is_subscriber: false, coverage_start_on: other_effective_on})
          enrollment.family = other_family
          enrollment
        end


        it 'should import enrollment' do

          enrollment_transcript = Importers::Transcripts::EnrollmentTranscript.new
          enrollment_transcript.transcript = transcript
          enrollment_transcript.other_enrollment = other_enrollment
          enrollment_transcript.market = 'individual'
          enrollment_transcript.process
          source_enrollment_1.reload
          source_family.reload

          expect(source_enrollment_1.void?).to be_truthy
          expect(source_enrollment_1.hbx_enrollment_members.size).to eq 1

          new_enrollment = source_family.active_household.hbx_enrollments.detect { |en| en != source_enrollment_1 }
          expect(new_enrollment.present?).to be_truthy
          expect(new_enrollment.hbx_enrollment_members.size).to eq 2
          expect(new_enrollment.hbx_enrollment_members.detect { |m| m.is_subscriber == false }.hbx_id).to eq spouse.hbx_id
          expect(new_enrollment.coverage_selected?).to be_truthy

          expect(enrollment_transcript.updates[:add][:hbx_enrollment_members]['hbx_id']).to eq ["Success", "Added hbx_id record on hbx_enrollment_members using EDI source"]
        end
      end

      context '.remove' do
        let(:compare) do
          {
            :base => {},
            :plan => {"update" => {}},
            :hbx_enrollment_members => {
              "update" => {"hbx_id:#{primary.hbx_id}" => {}},
              "remove" => {"hbx_id" => {"hbx_id" => spouse.hbx_id, "is_subscriber" => false, "coverage_start_on" => Date.new(2016, 1, 1), "coverage_end_on" => Date.new(2016, 1, 31)}}
            }
          }
        end

        let!(:source_enrollment_1) do
          enrollment = source_family.active_household.hbx_enrollments.build({hbx_id: '1000001', kind: 'individual', product: source_plan, effective_on: source_effective_on, aasm_state: 'coverage_selected'})
          source_family.family_members.each do |family_member|
            enrollment.hbx_enrollment_members.build({applicant_id: family_member.id, is_subscriber: family_member.is_primary_applicant, coverage_start_on: source_effective_on, eligibility_date: source_effective_on})
          end
          enrollment.family = source_family
          enrollment.save
          enrollment
        end

        let(:transcript) do
          {
            :source => {'_id' => source_enrollment_1.id},
            :compare => compare,
            :other => nil
          }
        end

        let(:other_enrollment) do
          enrollment = other_family.active_household.hbx_enrollments.build({hbx_id: '1000006', kind: 'individual', product: other_plan, effective_on: other_effective_on})
          enrollment.hbx_enrollment_members.build({applicant_id: other_family.primary_applicant.id, is_subscriber: true, coverage_start_on: other_effective_on})
          enrollment.hbx_enrollment_members.build({applicant_id: dependent1.id, is_subscriber: false, coverage_start_on: other_effective_on})
          enrollment.hbx_enrollment_members.build({applicant_id: dependent2.id, is_subscriber: false, coverage_start_on: other_effective_on})
          enrollment.family = other_family
          enrollment
        end

        it 'should import enrollment' do

          enrollment_transcript = Importers::Transcripts::EnrollmentTranscript.new
          enrollment_transcript.transcript = transcript
          enrollment_transcript.other_enrollment = other_enrollment
          enrollment_transcript.market = 'individual'
          enrollment_transcript.process

          source_enrollment_1.reload
          source_family.reload

          expect(source_enrollment_1.void?).to be_truthy
          expect(source_enrollment_1.hbx_enrollment_members.map(&:person)).to eq [person, spouse, child1, child2]

          new_enrollment = source_family.active_household.hbx_enrollments.detect { |en| en != source_enrollment_1 }

          expect(new_enrollment.present?).to be_truthy
          expect(new_enrollment.hbx_enrollment_members.map(&:person)).to eq [person, child1, child2]
          expect(new_enrollment.coverage_selected?).to be_truthy
          expect(enrollment_transcript.updates[:remove][:hbx_enrollment_members]['hbx_id']).to eq ["Success", "Removed hbx_id on hbx_enrollment_members"]
        end
      end
    end

    context 'plan' do


      context '.add' do

        let!(:source_enrollment_1) do
          enrollment = source_family.active_household.hbx_enrollments.build({hbx_id: '1000001', kind: 'individual', product: source_plan, effective_on: source_effective_on, aasm_state: 'coverage_selected'})
          source_family.family_members.each do |family_member|
            enrollment.hbx_enrollment_members.build({applicant_id: family_member.id, is_subscriber: family_member.is_primary_applicant, coverage_start_on: source_effective_on, eligibility_date: source_effective_on})
          end
          enrollment.family = source_family
          enrollment.save
          enrollment
        end

        let(:compare) do
          {
            :plan => {"remove" => {"hios_id" => {"name" => "BluePreferred PPO Standard Silver $2,000", "hios_id" => "78079DC0210004-01", "active_year" => 2016}},
                      "add" => {"hios_id" => {"name" => "KP DC Gold 1000/20/Dental/Ped Dental", "hios_id" => other_plan.hios_id.to_s, "active_year" => 2016}}}
          }
        end

        let(:transcript) do
          {
            :source => {'_id' => source_enrollment_1.id},
            :compare => compare,
            :other => nil
          }
        end

        it 'should create new enrollment with new plan' do

          expect(source_enrollment_1.product).to eq source_plan

          enrollment_transcript = Importers::Transcripts::EnrollmentTranscript.new
          enrollment_transcript.transcript = transcript
          enrollment_transcript.other_enrollment = other_enrollment
          enrollment_transcript.market = 'individual'
          enrollment_transcript.process
          source_family.reload
          source_enrollment_1.reload

          expect(source_enrollment_1.product).to eq source_plan
          expect(source_enrollment_1.void?).to be_truthy

          enrollment = source_family.active_household.hbx_enrollments.where(:hbx_id.ne => source_enrollment_1.hbx_id).first

          expect(enrollment.present?).to be_truthy
          expect(enrollment.coverage_terminated?).to be_truthy
          expect(enrollment_transcript.updates[:add][:plan]['hios_id']).to eq ["Success", "Added hios_id record on plan using EDI source"]
          expect(enrollment_transcript.updates[:remove][:plan]['hios_id']).to eq ["Ignored", "Ignored per Enrollment update rule set."]
        end
      end
    end

    context 'hbx_enrollment' do

      context '.new' do

        let(:compare) do
          {:new => {"new" => {"hbx_id" => other_enrollment.hbx_id.to_s}}}
        end

        let(:transcript) do
          {
            :source => {'_id' => source_enrollment_1.id},
            :compare => compare,
            :other => nil,
            :source_is_new => true
          }
        end

        let!(:source_enrollment_1) do
          enrollment = source_family.active_household.hbx_enrollments.build({hbx_id: '1000001', kind: 'individual', product: source_plan, effective_on: source_effective_on, aasm_state: 'coverage_selected'})
          enrollment.hbx_enrollment_members.build({applicant_id: primary.id, is_subscriber: true, coverage_start_on: source_effective_on, eligibility_date: source_effective_on})
          enrollment.hbx_enrollment_members.build({applicant_id: dependent.id, is_subscriber: false, coverage_start_on: source_effective_on, eligibility_date: source_effective_on})
          enrollment.family = source_family
          enrollment.save
          enrollment
        end

        it 'should create new enrollment' do
          enrollment_transcript = Importers::Transcripts::EnrollmentTranscript.new
          enrollment_transcript.transcript = transcript
          enrollment_transcript.other_enrollment = other_enrollment
          enrollment_transcript.market = 'individual'
          enrollment_transcript.process

          source_family.reload
          enrollment = source_family.active_household.hbx_enrollments.where(:hbx_id => other_enrollment.hbx_id).first
          expect(enrollment.present?).to be_truthy
          expect(enrollment.coverage_terminated?).to be_truthy
          expect(enrollment_transcript.updates[:new][:new]['hbx_id']).to eq ["Success", "Enrollment added successfully using EDI source"]
        end
      end

      context '.remove' do

        let!(:source_enrollment_1) do
          enrollment = source_family.active_household.hbx_enrollments.build({hbx_id: '1000001', kind: 'individual', product: source_plan, effective_on: source_effective_on, aasm_state: 'coverage_selected'})
          enrollment.hbx_enrollment_members.build({applicant_id: primary.id, is_subscriber: true, coverage_start_on: source_effective_on, eligibility_date: source_effective_on})
          enrollment.hbx_enrollment_members.build({applicant_id: dependent.id, is_subscriber: false, coverage_start_on: source_effective_on, eligibility_date: source_effective_on})
          enrollment.family = source_family
          enrollment.save
          enrollment
        end

        let!(:source_enrollment_2) do
          enrollment = source_family.active_household.hbx_enrollments.build({hbx_id: '1000002', kind: 'individual', product: source_plan, effective_on: (source_effective_on + 1.month), aasm_state: 'coverage_terminated'})
          enrollment.hbx_enrollment_members.build({applicant_id: primary.id, is_subscriber: true, coverage_start_on: (source_effective_on + 1.month), eligibility_date: (source_effective_on + 1.month)})
          enrollment.family = source_family
          enrollment.save
          enrollment
        end

        let!(:source_enrollment_3) do
          enrollment = source_family.active_household.hbx_enrollments.build({hbx_id: '1000003', kind: 'individual', product: source_plan, effective_on: (other_effective_on - 1.month), aasm_state: 'coverage_selected'})
          enrollment.hbx_enrollment_members.build({applicant_id: primary.id, is_subscriber: true, coverage_start_on: (other_effective_on - 1.month), eligibility_date: (other_effective_on - 1.month)})
          enrollment.family = source_family
          enrollment.save
          enrollment
        end

        let!(:source_enrollment_4) do
          enrollment = source_family.active_household.hbx_enrollments.build({hbx_id: '1000004', kind: 'individual', product: source_plan, effective_on: (source_effective_on + 2.months), aasm_state: 'coverage_selected'})
          enrollment.hbx_enrollment_members.build({applicant_id: primary.id, is_subscriber: true, coverage_start_on: (source_effective_on + 2.months), eligibility_date: (source_effective_on + 2.months)})
          enrollment.family = source_family
          enrollment.save
          enrollment
        end

        let(:transcript) do
          {
            :source => {'_id' => source_enrollment_1.id},
            :compare => compare,
            :other => nil
          }
        end

        let(:compare) do
          {:enrollment =>
               {"remove" =>
                    {"hbx_id" =>
                         [{"hbx_id" => source_enrollment_2.hbx_id.to_s,
                           "effective_on" => Date.new(2016, 1, 1),
                           "hios_id" => "81334DC0010004",
                           "plan_name" => "Delta Dental PPO Preferred Plan for Families",
                           "kind" => "individual",
                           "aasm_state" => "CoverageSelected",
                           "coverage_kind" => "dental"},
                          {"hbx_id" => source_enrollment_3.hbx_id.to_s,
                           "effective_on" => Date.new(2016, 1, 1),
                           "hios_id" => "81334DC0010004",
                           "plan_name" => "Delta Dental PPO Preferred Plan for Families",
                           "kind" => "individual",
                           "aasm_state" => "CoverageTerminated",
                           "coverage_kind" => "dental"},
                          {"hbx_id" => source_enrollment_4.hbx_id.to_s,
                           "effective_on" => Date.new(2016, 1, 1),
                           "hios_id" => "81334DC0010004",
                           "plan_name" => "Delta Dental PPO Preferred Plan for Families",
                           "kind" => "individual",
                           "aasm_state" => "CoverageTerminated",
                           "coverage_kind" => "dental"}]}}}
        end


        it 'should remove enrollments' do

          enrollment_transcript = Importers::Transcripts::EnrollmentTranscript.new
          enrollment_transcript.transcript = transcript
          enrollment_transcript.other_enrollment = other_enrollment
          enrollment_transcript.market = 'individual'
          enrollment_transcript.process

          source_enrollment_1.reload
          source_enrollment_2.reload
          source_enrollment_3.reload
          source_enrollment_4.reload

          expect(source_enrollment_2.coverage_terminated?).to be_truthy
          expect(source_enrollment_3.void?).to be_truthy
          expect(source_enrollment_4.void?).to be_truthy
        end
      end
    end
  end
end

