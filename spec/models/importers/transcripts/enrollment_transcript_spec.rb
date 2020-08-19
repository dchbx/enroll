require 'rails_helper'

RSpec.describe Importers::Transcripts::EnrollmentTranscript, type: :model, dbclean: :after_each do

  context ".process" do

    let!(:spouse)  { FactoryGirl.create(:person)}
    let!(:child1)  { FactoryGirl.create(:person)}
    let!(:child2)  { FactoryGirl.create(:person)}
    let!(:person)  { FactoryGirl.create(:person)}

    let(:source_effective_on) { Date.new(TimeKeeper.date_of_record.year, 1, 1) }
    let(:other_effective_on) { Date.new(TimeKeeper.date_of_record.year, 3, 1) }
    let!(:other_plan) { FactoryGirl.create(:plan, market: 'individual') }
    let!(:source_plan) { FactoryGirl.create(:plan, market: 'individual') }

    let(:other_family) {
      family = Family.new({
        hbx_assigned_id: '24112',
        e_case_id: "6754632"
        })

      primary = family.family_members.build(is_primary_applicant: true, person: person)
      family.save
      family
    }

    let(:dependent1) {
      other_family.family_members.build(is_primary_applicant: false, person: spouse)
    }

    let(:dependent2) {
      other_family.family_members.build(is_primary_applicant: false, person: child1)
    }

    let(:other_enrollment) {
      enrollment = other_family.active_household.hbx_enrollments.build({ hbx_id: '1000006', kind: 'individual',plan: other_plan, effective_on: other_effective_on, terminated_on: other_effective_on.end_of_month })
      enrollment.hbx_enrollment_members.build({applicant_id: other_family.primary_applicant.id, is_subscriber: true, coverage_start_on: other_effective_on })
      enrollment.hbx_enrollment_members.build({applicant_id: dependent1.id, is_subscriber: false, coverage_start_on: other_effective_on })
      enrollment.hbx_enrollment_members.build({applicant_id: dependent2.id, is_subscriber: false, coverage_start_on: other_effective_on })
      enrollment
    }

    let!(:source_family) {


      family = Family.new({ hbx_assigned_id: '25112', e_case_id: "6754632" })
      family.family_members.build(is_primary_applicant: true, person: person)
      family.family_members.build(is_primary_applicant: false, person: spouse)
      family.family_members.build(is_primary_applicant: false, person: child1)
      family.family_members.build(is_primary_applicant: false, person: child2)

      person.person_relationships.create(predecessor_id: person.id , successor_id: spouse.id, kind: "spouse", family_id: family.id)
      spouse.person_relationships.create(predecessor_id: spouse.id , successor_id: person.id, kind: "spouse", family_id: family.id)
      person.person_relationships.create(predecessor_id: person.id , successor_id: child1.id, kind: "parent", family_id: family.id)
      child1.person_relationships.create(predecessor_id: child1.id , successor_id: person.id, kind: "child", family_id: family.id)
      person.person_relationships.create(predecessor_id: person.id , successor_id: child2.id, kind: "parent", family_id: family.id)
      child2.person_relationships.create(predecessor_id: child2.id , successor_id: person.id, kind: "child", family_id: family.id)

      person.save!
      child1.save!
      child2.save!
      family.save!
      family.reload
    }

    let(:primary) { source_family.primary_applicant }
    let(:dependent) { source_family.family_members.detect{|fm| !fm.is_primary_applicant }}

    let(:factory) { Transcripts::EnrollmentTranscript.new }
    let(:importer) { Importers::Transcripts::EnrollmentTranscript.new }

    context 'hbx_enrollment_members' do 

      context '.add' do 

        let(:compare) {
          {
            :base =>{},
            :plan =>{"update"=>{}}, 
            :hbx_enrollment_members =>{
              "update"=>{"hbx_id:#{primary.hbx_id}"=>{}}, 
              "add"=>{"hbx_id"=>{"hbx_id"=>spouse.hbx_id, "is_subscriber"=>false, "coverage_start_on"=> Date.new(TimeKeeper.date_of_record.year,1,1), "coverage_end_on"=>Date.new(TimeKeeper.date_of_record.year,1,31)}}
            }
          }
        }

        let!(:source_enrollment_1) {
          enrollment = source_family.active_household.hbx_enrollments.build({ hbx_id: '1000001', kind: 'individual',plan: source_plan, effective_on: source_effective_on, aasm_state: 'coverage_selected'})
          enrollment.hbx_enrollment_members.build({applicant_id: primary.id, is_subscriber: true, coverage_start_on: source_effective_on, eligibility_date: source_effective_on })
          enrollment.save
          enrollment
        }

        let(:transcript) { 
          {
            :source => {'_id' => source_enrollment_1.id },
            :compare => compare,
            :other => nil
          }
        }

        let(:other_enrollment) {
          enrollment = other_family.active_household.hbx_enrollments.build({ hbx_id: '1000006', kind: 'individual',plan: other_plan, effective_on: other_effective_on })
          enrollment.hbx_enrollment_members.build({applicant_id: other_family.primary_applicant.id, is_subscriber: true, coverage_start_on: other_effective_on })
          enrollment.hbx_enrollment_members.build({applicant_id: dependent1.id, is_subscriber: false, coverage_start_on: other_effective_on })
          enrollment.hbx_enrollment_members.build({applicant_id: dependent2.id, is_subscriber: false, coverage_start_on: other_effective_on })
          enrollment
        }


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

          new_enrollment = source_family.active_household.hbx_enrollments.detect{|en| en != source_enrollment_1 }
          expect(new_enrollment.present?).to be_truthy
          expect(new_enrollment.hbx_enrollment_members.size).to eq 2
          expect(new_enrollment.hbx_enrollment_members.detect{|m| m.is_subscriber == false}.hbx_id).to eq spouse.hbx_id 
          expect(new_enrollment.coverage_selected?).to be_truthy

          expect(enrollment_transcript.updates[:add][:hbx_enrollment_members]['hbx_id']).to eq ["Success", "Added hbx_id record on hbx_enrollment_members using EDI source"]
        end
      end

      context '.remove' do 
        let(:compare) {
          {
            :base =>{},
            :plan =>{"update"=>{}}, 
            :hbx_enrollment_members =>{
              "update"=>{"hbx_id:#{primary.hbx_id}"=>{}}, 
              "remove"=>{"hbx_id"=>{"hbx_id"=>spouse.hbx_id, "is_subscriber"=>false, "coverage_start_on"=> Date.new(2016,1,1), "coverage_end_on"=>Date.new(2016,1,31)}}
            }
          }
        }

        let!(:source_enrollment_1) {
          enrollment = source_family.active_household.hbx_enrollments.build({ hbx_id: '1000001', kind: 'individual',plan: source_plan, effective_on: source_effective_on, aasm_state: 'coverage_selected'})
          source_family.family_members.each do |family_member|
            enrollment.hbx_enrollment_members.build({applicant_id: family_member.id, is_subscriber: family_member.is_primary_applicant, coverage_start_on: source_effective_on, eligibility_date: source_effective_on })
          end
          enrollment.save
          enrollment
        }

        let(:transcript) { 
          {
            :source => {'_id' => source_enrollment_1.id },
            :compare => compare,
            :other => nil
          }
        }

        let(:other_enrollment) {
          enrollment = other_family.active_household.hbx_enrollments.build({ hbx_id: '1000006', kind: 'individual',plan: other_plan, effective_on: other_effective_on })
          enrollment.hbx_enrollment_members.build({applicant_id: other_family.primary_applicant.id, is_subscriber: true, coverage_start_on: other_effective_on })
          enrollment.hbx_enrollment_members.build({applicant_id: dependent1.id, is_subscriber: false, coverage_start_on: other_effective_on })
          enrollment.hbx_enrollment_members.build({applicant_id: dependent2.id, is_subscriber: false, coverage_start_on: other_effective_on })
          enrollment
        }

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

          new_enrollment = source_family.active_household.hbx_enrollments.detect{|en| en != source_enrollment_1 }

          expect(new_enrollment.present?).to be_truthy
          expect(new_enrollment.hbx_enrollment_members.map(&:person)).to eq [person, child1, child2]
          expect(new_enrollment.coverage_selected?).to be_truthy
          expect(enrollment_transcript.updates[:remove][:hbx_enrollment_members]['hbx_id']).to eq ["Success", "Removed hbx_id on hbx_enrollment_members"]
        end
      end
    end

    context 'plan' do 


      context '.add' do 

        let!(:source_enrollment_1) {
          enrollment = source_family.active_household.hbx_enrollments.build({ hbx_id: '1000001', kind: 'individual',plan: source_plan, effective_on: source_effective_on, aasm_state: 'coverage_selected'})
          source_family.family_members.each do |family_member|
            enrollment.hbx_enrollment_members.build({applicant_id: family_member.id, is_subscriber: family_member.is_primary_applicant, coverage_start_on: source_effective_on, eligibility_date: source_effective_on })
          end
          enrollment.save
          enrollment
        }
        
         let(:compare) {
           {
             :plan =>{ "remove"=>{"hios_id"=>{"name"=>"BluePreferred PPO Standard Silver $2,000", "hios_id"=>"78079DC0210004-01", "active_year"=>2016}},
                       "add"=>{"hios_id"=>{"name"=>"KP DC Gold 1000/20/Dental/Ped Dental", "hios_id"=>"#{other_plan.hios_id}", "active_year"=>2016}}}
           }
         }

         let(:transcript) { 
           {
            :source => {'_id' => source_enrollment_1.id },
            :compare => compare,
            :other => nil
           }
         }

         it 'should create new enrollment with new plan' do

          expect(source_enrollment_1.plan).to eq source_plan

          enrollment_transcript = Importers::Transcripts::EnrollmentTranscript.new
          enrollment_transcript.transcript = transcript
          enrollment_transcript.other_enrollment = other_enrollment
          enrollment_transcript.market = 'individual'
          enrollment_transcript.process
          source_family.reload
          source_enrollment_1.reload

          expect(source_enrollment_1.plan).to eq source_plan
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

        let(:compare) {
          {:new =>{"new"=>{"hbx_id"=>"#{other_enrollment.hbx_id}"}}}
        }

        let(:transcript) { 
          {
            :source => {'_id' => source_enrollment_1.id },
            :compare => compare,
            :other => nil,
            :source_is_new => true
          }
        }

        let!(:source_enrollment_1) {
          enrollment = source_family.active_household.hbx_enrollments.build({ hbx_id: '1000001', kind: 'individual',plan: source_plan, effective_on: source_effective_on, aasm_state: 'coverage_selected'})
          enrollment.hbx_enrollment_members.build({applicant_id: primary.id, is_subscriber: true, coverage_start_on: source_effective_on, eligibility_date: source_effective_on })
          enrollment.hbx_enrollment_members.build({applicant_id: dependent.id, is_subscriber: false, coverage_start_on: source_effective_on, eligibility_date: source_effective_on })
          enrollment.save
          enrollment
        }

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

        let!(:source_enrollment_1) {
          enrollment = source_family.active_household.hbx_enrollments.build({ hbx_id: '1000001', kind: 'individual',plan: source_plan, effective_on: source_effective_on, aasm_state: 'coverage_selected'})
          enrollment.hbx_enrollment_members.build({applicant_id: primary.id, is_subscriber: true, coverage_start_on: source_effective_on, eligibility_date: source_effective_on })
          enrollment.hbx_enrollment_members.build({applicant_id: dependent.id, is_subscriber: false, coverage_start_on: source_effective_on, eligibility_date: source_effective_on })
          enrollment.save
          enrollment
        }

        let!(:source_enrollment_2) {
          enrollment = source_family.active_household.hbx_enrollments.build({ hbx_id: '1000002', kind: 'individual',plan: source_plan, effective_on: (source_effective_on + 1.month), aasm_state: 'coverage_terminated'})
          enrollment.hbx_enrollment_members.build({applicant_id: primary.id, is_subscriber: true, coverage_start_on: (source_effective_on + 1.month), eligibility_date: (source_effective_on + 1.month) })
          enrollment.save
          enrollment
        }

        let!(:source_enrollment_3) {
          enrollment = source_family.active_household.hbx_enrollments.build({ hbx_id: '1000003', kind: 'individual',plan: source_plan, effective_on: (other_effective_on - 1.month), aasm_state: 'coverage_selected'})
          enrollment.hbx_enrollment_members.build({applicant_id: primary.id, is_subscriber: true, coverage_start_on: (other_effective_on - 1.month), eligibility_date: (other_effective_on - 1.month) })
          enrollment.save
          enrollment
        }

        let!(:source_enrollment_4) {
          enrollment = source_family.active_household.hbx_enrollments.build({ hbx_id: '1000004', kind: 'individual',plan: source_plan, effective_on: (source_effective_on + 2.months), aasm_state: 'coverage_selected'})
          enrollment.hbx_enrollment_members.build({applicant_id: primary.id, is_subscriber: true, coverage_start_on: (source_effective_on + 2.months), eligibility_date: (source_effective_on + 2.months) })
          enrollment.save
          enrollment
        }

        let(:transcript) { 
          {
            :source => {'_id' => source_enrollment_1.id },
            :compare => compare,
            :other => nil
          }
        }

        let(:compare) {
          {:enrollment=>
            {"remove"=>
              {"hbx_id"=>
                [{"hbx_id"=>"#{source_enrollment_2.hbx_id}",
                  "effective_on"=>Date.new(2016,1,1),
                  "hios_id"=>"81334DC0010004",
                  "plan_name"=>"Delta Dental PPO Preferred Plan for Families",
                  "kind"=>"individual",
                  "aasm_state"=>"CoverageSelected",
                  "coverage_kind"=>"dental"
                  },
                  {"hbx_id"=>"#{source_enrollment_3.hbx_id}",
                    "effective_on"=>Date.new(2016,1,1),
                    "hios_id"=>"81334DC0010004",
                    "plan_name"=>"Delta Dental PPO Preferred Plan for Families",
                    "kind"=>"individual",
                    "aasm_state"=>"CoverageTerminated",
                    "coverage_kind"=>"dental"
                  },
                  {"hbx_id"=>"#{source_enrollment_4.hbx_id}",
                    "effective_on"=>Date.new(2016,1,1),
                    "hios_id"=>"81334DC0010004",
                    "plan_name"=>"Delta Dental PPO Preferred Plan for Families",
                    "kind"=>"individual",
                    "aasm_state"=>"CoverageTerminated",
                    "coverage_kind"=>"dental"
                  }]
                }
              }
          }
        }


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

