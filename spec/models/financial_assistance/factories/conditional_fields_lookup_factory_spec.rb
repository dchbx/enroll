require 'rails_helper'

RSpec.describe "::FinancialAssistance::Factories::ConditionalFieldsLookupFactory" do
  subject do
    ::FinancialAssistance::Factories::ConditionalFieldsLookupFactory
  end

  include_examples 'submitted application with one member and one applicant'

  describe 'conditionally_displayable?' do

    describe 'is_joint_tax_filing' do
      context 'when the current person is not filing jointly' do
        before do
          @instance = subject.new('applicant', applicant1.id, :is_joint_tax_filing)
        end

        it 'should not return true' do
          expect(@instance.conditionally_displayable?).to be_falsey
        end
      end

      context 'when the current person is not filing jointly with their spouse' do
        before do
          applicant1.update_attributes!(is_required_to_file_taxes: true)
          dep_person = FactoryGirl.create(:person)
          primary_person.person_relationships.create(predecessor_id: primary_person.id, successor_id: dep_person.id, family_id: family.id, kind: 'spouse')
          @instance = subject.new('applicant', applicant1.id, :is_joint_tax_filing)
        end

        it 'should return true' do
          expect(@instance.conditionally_displayable?).to be_truthy
        end
      end
    end

    describe 'claimed_as_tax_dependent_by' do
      context 'where the current applicant is not claimed as tax dependent' do
        before do
          @instance = subject.new('applicant', applicant1.id, :claimed_as_tax_dependent_by)
        end

        it 'should not return true' do
          expect(@instance.conditionally_displayable?).to be_falsey
        end
      end

      context 'where the current applicant is claimed as tax dependent' do
        before do
          applicant1.update_attributes!(is_claimed_as_tax_dependent: true)
          @instance = subject.new('applicant', applicant1.id, :claimed_as_tax_dependent_by)
        end

        it 'should return true' do
          expect(@instance.conditionally_displayable?).to be_truthy
        end
      end
    end

    describe 'is_ssn_applied' do
      context 'where the current applicant has not applied for SSN' do
        before do
          @instance = subject.new('applicant', applicant1.id, :is_ssn_applied)
        end

        it 'should not return true' do
          expect(@instance.conditionally_displayable?).to be_falsey
        end
      end

      [true, false].each do |boolean|
        context 'where the current applicant has applied for SSN' do
          before do
            primary_person.update_attributes!(no_ssn: '1')
            applicant1.update_attributes!(is_ssn_applied: boolean)
            @instance = subject.new('applicant', applicant1.id, :is_ssn_applied)
          end

          it 'should return true' do
            expect(@instance.conditionally_displayable?).to be_truthy
          end
        end
      end

      [true, false].each do |boolean|
        context 'where the current applicant has applied for SSN but has an SSN' do
          before do
            applicant1.update_attributes!(is_ssn_applied: boolean)
            @instance = subject.new('applicant', applicant1.id, :is_ssn_applied)
          end

          it 'should return false' do
            expect(@instance.conditionally_displayable?).to eq false
          end
        end
      end
    end

    describe 'non_ssn_apply_reason' do
      context 'where the current applicant did not answer the question' do
        before do
          @instance = subject.new('applicant', applicant1.id, :non_ssn_apply_reason)
        end

        it 'should not return true' do
          expect(@instance.conditionally_displayable?).to be_falsey
        end
      end

      context 'where the current applicant answered false to is_ssn_applied and applicant has no ssn' do
        before do
          primary_person.update_attributes!(no_ssn: '1')
          applicant1.update_attributes!(is_ssn_applied: false, non_ssn_apply_reason: 'not eligible')
          @instance = subject.new('applicant', applicant1.id, :non_ssn_apply_reason)
        end

        it 'should return true' do
          expect(@instance.conditionally_displayable?).to be_truthy
        end
      end

      context 'where the current applicant answered false to is_ssn_applied and applicant has a valid ssn' do
        before do
          applicant1.update_attributes!(is_ssn_applied: false, non_ssn_apply_reason: 'not eligible')
          @instance = subject.new('applicant', applicant1.id, :non_ssn_apply_reason)
        end

        it 'should return false' do
          expect(@instance.conditionally_displayable?).to eq false
        end
      end

      context 'where the current applicant answered false to is_ssn_applied' do
        before do
          applicant1.update_attributes!(is_ssn_applied: true, non_ssn_apply_reason: 'not eligible')
          @instance = subject.new('applicant', applicant1.id, :non_ssn_apply_reason)
        end

        it 'should return true' do
          expect(@instance.conditionally_displayable?).to be_falsey
        end
      end
    end

    describe 'for pregnant' do
      context 'where the current applicant is not pregnant' do
        before do
          @instance = subject.new('applicant', applicant1.id,:pregnancy_due_on)
        end

        it 'should not return true' do
          expect(@instance.conditionally_displayable?).to be_falsey
        end
      end

      context 'where the current applicant is pregnant' do
        before do
          applicant1.update_attributes!(is_pregnant: true)
          @instance = subject.new('applicant', applicant1.id,:pregnancy_due_on)
        end

        it 'should return true' do
          expect(@instance.conditionally_displayable?).to be_truthy
        end
      end
    end

    describe 'for not pregnant' do
      context 'where the current applicant is pregnant' do
        before do
          @instance = subject.new('applicant', applicant1.id, :is_post_partum_period)
        end

        it 'should not return true' do
          expect(@instance.conditionally_displayable?).to be_falsey
        end
      end

      context 'where the current applicant is not pregnant' do
        before do
          applicant1.update_attributes!(is_pregnant: false)
          @instance = subject.new('applicant', applicant1.id, :is_post_partum_period)
        end

        it 'should return true' do
          expect(@instance.conditionally_displayable?).to be_truthy
        end
      end
    end

    describe 'for not pregnant, pregnancy_end_on' do
      context 'where the current applicant is pregnant' do
        before do
          @instance = subject.new('applicant', applicant1.id, :pregnancy_end_on)
        end

        it 'should not return true' do
          expect(@instance.conditionally_displayable?).to be_falsey
        end
      end

      context 'where the current applicant is not pregnant, is in post_partum_period and did not pregnancy_end_on' do
        before do
          applicant1.update_attributes!(is_pregnant: false, is_post_partum_period: true)
          @instance = subject.new('applicant', applicant1.id, :pregnancy_end_on)
        end

        it 'should return false' do
          expect(@instance.conditionally_displayable?).to eq false
        end
      end

      context 'where the current applicant is not pregnant, is in post_partum_period and entered pregnancy_end_on' do
        before do
          applicant1.update_attributes!(is_pregnant: false, is_post_partum_period: true, pregnancy_end_on: (TimeKeeper.date_of_record - 20.days))
          @instance = subject.new('applicant', applicant1.id, :pregnancy_end_on)
        end

        it 'should return true' do
          expect(@instance.conditionally_displayable?).to be_truthy
        end
      end
    end

    describe 'is_enrolled_on_medicaid' do
      context 'where the current applicant has enrolled in Medicaid' do
        before do
          @instance = subject.new('applicant', applicant1.id, :is_enrolled_on_medicaid)
        end

        it 'should not return true' do
          expect(@instance.conditionally_displayable?).to be_falsey
        end
      end

      context 'where the current applicant has not enrolled in Medicaid' do
        before do
          applicant1.update_attributes!(is_post_partum_period: true)
          @instance = subject.new('applicant', applicant1.id, :is_enrolled_on_medicaid)
        end

        it 'should return true' do
          expect(@instance.conditionally_displayable?).to be_truthy
        end
      end
    end

    describe 'is_former_foster_care' do
      context 'where the current applicant has enrolled in Medicaid' do
        before do
          @instance = subject.new('applicant', applicant1.id, :is_former_foster_care)
        end

        it 'should not return true' do
          expect(@instance.conditionally_displayable?).to be_falsey
        end
      end

      context 'where the current applicant has not enrolled in Medicaid' do
        before do
          primary_person.update_attributes(dob: (TimeKeeper.date_of_record - 21.years))
          @instance = subject.new('applicant', applicant1.id, :is_former_foster_care)
        end

        it 'should return true' do
          expect(@instance.conditionally_displayable?).to be_truthy
        end
      end
    end

    describe 'where the applicant was in foster care' do
      context 'where the current applicant was in foster care' do
        before do
          @instance = subject.new('applicant', applicant1.id, :foster_care_us_state)
        end

        it 'should not return true' do
          expect(@instance.conditionally_displayable?).to be_falsey
        end
      end

      context 'where the current applicant has not enrolled in Medicaid' do
        before do
          applicant1.update_attributes!(is_former_foster_care: true)
          @instance = subject.new('applicant', applicant1.id, :foster_care_us_state)
        end

        it 'should return false' do
          expect(@instance.conditionally_displayable?).to eq false
        end
      end

      context 'where the current applicant has not enrolled in Medicaid and also satisfies foster care age' do
        before do
          primary_person.update_attributes(dob: (TimeKeeper.date_of_record - 21.years))
          applicant1.update_attributes!(is_former_foster_care: true)
          @instance = subject.new('applicant', applicant1.id, :foster_care_us_state)
        end

        it 'should return true' do
          expect(@instance.conditionally_displayable?).to be_truthy
        end
      end
    end

    describe 'is_student' do
      context 'where the current applicant has enrolled in Medicaid' do
        before do
          @instance = subject.new('applicant', applicant1.id, :is_student)
        end

        it 'should not return true' do
          expect(@instance.conditionally_displayable?).to be_falsey
        end
      end

      context 'where the current applicant has not enrolled in Medicaid' do
        before do
          primary_person.update_attributes(dob: (TimeKeeper.date_of_record - 18.years))
          @instance = subject.new('applicant', applicant1.id, :is_student)
        end

        it 'should return true' do
          expect(@instance.conditionally_displayable?).to be_truthy
        end
      end
    end

    describe 'where applicant is a student' do
      context 'where the current applicant not in the range of a student' do
        before do
          @instance = subject.new('applicant', applicant1.id, :student_kind)
        end

        it 'should not return true' do
          expect(@instance.conditionally_displayable?).to be_falsey
        end
      end

      context 'where the current applicant is a student but not in the date range anymore' do
        before do
          applicant1.update_attributes!(is_student: true)
          @instance = subject.new('applicant', applicant1.id, :student_kind)
        end

        it 'should return false' do
          expect(@instance.conditionally_displayable?).to eq false
        end
      end

      context 'for an applicant who is a student and also in the student date range' do
        before do
          primary_person.update_attributes(dob: (TimeKeeper.date_of_record - 18.years))
          applicant1.update_attributes!(is_student: true)
          @instance = subject.new('applicant', applicant1.id, :student_kind)
        end

        it 'should return true' do
          expect(@instance.conditionally_displayable?).to be_truthy
        end
      end
    end

    describe 'incomes_jobs' do
      context 'when the current do not have any job incomes' do
        before do
          @instance = subject.new('applicant', applicant1.id, :incomes_jobs)
        end

        it 'should not return true' do
          expect(@instance.conditionally_displayable?).to be_falsey
        end
      end

      context 'when the current do have any job incomes' do
        before do
          applicant1.update_attributes!(has_job_income: true)
          @instance = subject.new('applicant', applicant1.id, :incomes_jobs)
        end

        it 'should return true' do
          expect(@instance.conditionally_displayable?).to be_truthy
        end
      end
    end

    describe 'is_requesting_voter_registration_application_in_mail' do
      context 'when the current person did not answer is_requesting_voter_registration_application_in_mail' do
        before do
          @instance = subject.new('application', application.id, :is_requesting_voter_registration_application_in_mail)
        end

        it 'should not return true' do
          expect(@instance.conditionally_displayable?).to be_falsey
        end
      end

      [true, false].each do |result|
        context 'when the current person answered is_requesting_voter_registration_application_in_mail' do
          before do
            application.update_attributes!(is_requesting_voter_registration_application_in_mail: result)
            @instance = subject.new('application', application.id, :is_requesting_voter_registration_application_in_mail)
          end

          it 'should return true' do
            expect(@instance.conditionally_displayable?).to be_truthy
          end
        end
      end
    end

    describe 'years_to_renew' do
      context 'when the current person did not answer years_to_renew' do
        before do
          @instance = subject.new('application', application.id, :years_to_renew)
        end

        it 'should not return true' do
          expect(@instance.conditionally_displayable?).to be_falsey
        end
      end

      (0..5).each do |result|
        context 'when the current person answered years_to_renew' do
          before do
            application.update_attributes!(years_to_renew: result)
            @instance = subject.new('application', application.id, :years_to_renew)
          end

          it 'should return true' do
            expect(@instance.conditionally_displayable?).to be_truthy
          end
        end
      end
    end

    describe 'parent_living_out_of_home_terms' do
      context 'when the current person did not answer parent_living_out_of_home_terms' do
        before do
          @instance = subject.new('application', application.id, :parent_living_out_of_home_terms)
        end

        it 'should not return true' do
          expect(@instance.conditionally_displayable?).to be_falsey
        end
      end

      [true, false].each do |result|
        context 'when the current person answered parent_living_out_of_home_terms' do
          before do
            application.update_attributes!(attestation_terms: result, parent_living_out_of_home_terms: result)
            @instance = subject.new('application', application.id, :parent_living_out_of_home_terms)
          end

          it 'should return true' do
            expect(@instance.conditionally_displayable?).to be_truthy
          end
        end
      end
    end
  end
end
