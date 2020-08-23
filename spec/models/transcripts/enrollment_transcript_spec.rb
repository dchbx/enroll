require 'rails_helper'

RSpec.describe Transcripts::EnrollmentTranscript, type: :model, dbclean: :after_each do

  describe "find_or_build_family" do

    let!(:spouse) { FactoryBot.create(:person) }
    let!(:child1) { FactoryBot.create(:person) }
    let!(:child2) { FactoryBot.create(:person) }
    let!(:person)  { FactoryBot.create(:person)}

    context "Family already exists" do

      let(:source_effective_on) { Date.new(TimeKeeper.date_of_record.year, 1, 1) }
      let(:other_effective_on) { Date.new(TimeKeeper.date_of_record.year, 3, 1) }

      let(:other_plan) { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
      let(:source_plan) { FactoryBot.create(:benefit_markets_products_health_products_health_product) }

      let(:other_family) {
        family = FactoryBot.build(:family, :with_primary_family_member, person: person, hbx_assigned_id: '24112', e_case_id: "6754632")
        family.relate_new_member(spouse, 'spouse')
        family.save
        family
      }

      let(:dependent2) do
        dependent = other_family.relate_new_member(child1, 'child')
        dependent.save
        dependent
      end

      let(:other_enrollment) do
        enrollment = other_family.active_household.hbx_enrollments.build({hbx_id: '1000001', family: other_family, kind: 'individual', product: other_plan, effective_on: other_effective_on})
        enrollment.hbx_enrollment_members.build({applicant_id: other_family.primary_applicant.id, is_subscriber: true, coverage_start_on: other_effective_on})
        enrollment.hbx_enrollment_members.build({applicant_id: dependent2.id, is_subscriber: false, coverage_start_on: other_effective_on})
        enrollment.family = other_family
        enrollment
      end

      let(:source_enrollment_hbx_id1) { '1000001' }
      let(:source_enrollment_hbx_id2) { '1000002' }

      let(:source_family) do
        family = FactoryBot.build(:family, :with_primary_family_member, person: person, hbx_assigned_id: '25112', e_case_id: "6754632")
        family.relate_new_member(spouse, 'spouse')
        family.relate_new_member(child1, 'child')
        family.relate_new_member(child2, 'child')
        family.save

        enrollment = family.active_household.hbx_enrollments.build({ hbx_id: source_enrollment_hbx_id1, kind: 'individual',product: source_plan, effective_on: (source_effective_on + 2.months), aasm_state: 'coverage_selected', family_id: family.id})
        enrollment.hbx_enrollment_members.build({applicant_id: family.primary_applicant.id, is_subscriber: true, coverage_start_on: source_effective_on, eligibility_date: source_effective_on })
        enrollment.hbx_enrollment_members.build({applicant_id: family.family_members[1].id, is_subscriber: false, coverage_start_on: source_effective_on, eligibility_date: source_effective_on })

        enrollment.save!

        enrollment = family.active_household.hbx_enrollments.build hbx_id: source_enrollment_hbx_id2, kind: 'individual',product: source_plan, effective_on: source_effective_on, aasm_state: 'coverage_selected', family_id: family.id
        enrollment.hbx_enrollment_members.build applicant_id: family.primary_applicant.id, is_subscriber: true, coverage_start_on: (source_effective_on + 1.month), eligibility_date: (source_effective_on + 1.month)
        enrollment.save!

        family
      end

      context "and enrollment member missing & plan hios is different" do

        it 'should have differences on hbx enrollment member and plan' do
          source_family

          factory = Transcripts::EnrollmentTranscript.new
          factory.find_or_build(other_enrollment)
          transcript = factory.transcript

          expect(transcript[:compare]['hbx_enrollment_members']['add']).to be_present
          expect(transcript[:compare]['hbx_enrollment_members']['add']['hbx_id']['hbx_id']).to eq dependent2.hbx_id
          expect(transcript[:compare]['hbx_enrollment_members']['remove']).to be_present
          expect(transcript[:compare]['hbx_enrollment_members']['remove']['hbx_id']['hbx_id']).to eq spouse.hbx_id

          expect(transcript[:compare]['plan']['add']['hios_id']['hios_id']).to eq other_plan.hios_id
          expect(transcript[:compare]['plan']['remove']).to be_present
          expect(transcript[:compare]['plan']['remove']['hios_id']['hios_id']).to eq source_plan.hios_id
        end
      end

      context 'other enrollement not matching with the source enrollment hbx_id' do
        let(:source_enrollment_hbx_id1) { '1000003' }

        it 'should match enrollments of same coverage kind, market under primary' do
          source_family

          factory = Transcripts::EnrollmentTranscript.new
          factory.find_or_build(other_enrollment)
          transcript = factory.transcript

          expect(transcript[:compare]['enrollment']['remove']['hbx_id'][0]['hbx_id']).to eq source_enrollment_hbx_id2
        end
      end
    end
  end
end
