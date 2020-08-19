require 'rails_helper'

RSpec.describe Transcripts::EnrollmentTranscript, type: :model, dbclean: :after_each do

  describe "find_or_build_family" do

    let!(:spouse)  { FactoryGirl.create(:person)}
    let!(:child1)  { FactoryGirl.create(:person)}
    let!(:child2)  { FactoryGirl.create(:person)}
    let!(:person)  { FactoryGirl.create(:person)}

    context "Family already exists" do

      let(:source_effective_on) { Date.new(TimeKeeper.date_of_record.year, 1, 1) }
      let(:other_effective_on) { Date.new(TimeKeeper.date_of_record.year, 3, 1) }
      let!(:other_plan) { FactoryGirl.create(:plan) }
      let!(:source_plan) { FactoryGirl.create(:plan) }

      let(:other_family) {
        family = Family.new({
          hbx_assigned_id: '24112',
          e_case_id: "6754632"
          })

        primary = family.family_members.build(is_primary_applicant: true, person: person)
        dependent1 = family.family_members.build(is_primary_applicant: true, person: spouse)
        family
      }

      let(:dependent2) {
        other_family.family_members.build(is_primary_applicant: false, person: child1)
      }

      let(:other_enrollment) {
        enrollment = other_family.active_household.hbx_enrollments.build({ hbx_id: '1000001', kind: 'individual',plan: other_plan, effective_on: other_effective_on })
        enrollment.hbx_enrollment_members.build({applicant_id: other_family.primary_applicant.id, is_subscriber: true, coverage_start_on: other_effective_on })
        enrollment.hbx_enrollment_members.build({applicant_id: dependent2.id, is_subscriber: false, coverage_start_on: other_effective_on })
        enrollment
      }

      let(:source_enrollment_hbx_id1) { '1000001' }
      let(:source_enrollment_hbx_id2) { '1000002' }

      let(:source_family) { 
        family = Family.new({ hbx_assigned_id: '25112', e_case_id: "6754632" })
        person.person_relationships.update_all(family_id: family.id)
        primary = family.family_members.build(is_primary_applicant: true, person: person)
        dependent = family.family_members.build(is_primary_applicant: false, person: spouse)

        person.person_relationships.create(predecessor_id: person.id, successor_id: spouse.id, kind: "spouse", family_id: family.id)
        person.person_relationships.create(predecessor_id: person.id, successor_id: child1.id, kind: "child", family_id: family.id)
        person.person_relationships.create(predecessor_id: person.id, successor_id: child2.id, kind: "child", family_id: family.id)

        enrollment = family.active_household.hbx_enrollments.build({ hbx_id: source_enrollment_hbx_id1, kind: 'individual',plan: source_plan, effective_on: (source_effective_on + 2.months), aasm_state: 'coverage_selected' })
        enrollment.hbx_enrollment_members.build({applicant_id: primary.id, is_subscriber: true, coverage_start_on: source_effective_on, eligibility_date: source_effective_on })
        enrollment.hbx_enrollment_members.build({applicant_id: dependent.id, is_subscriber: false, coverage_start_on: source_effective_on, eligibility_date: source_effective_on })
        enrollment.save!

        enrollment = family.active_household.hbx_enrollments.build({ hbx_id: source_enrollment_hbx_id2, kind: 'individual',plan: source_plan, effective_on: (source_effective_on), aasm_state: 'coverage_selected'})
        enrollment.hbx_enrollment_members.build({applicant_id: primary.id, is_subscriber: true, coverage_start_on: (source_effective_on + 1.month), eligibility_date: (source_effective_on + 1.month) })
        family.save
        family
       }

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

