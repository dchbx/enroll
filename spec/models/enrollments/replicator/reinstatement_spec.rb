require 'rails_helper'
require 'aasm/rspec'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe Enrollments::Replicator::Reinstatement, :type => :model, dbclean: :around_each do

  describe 'initial employer',  dbclean: :around_each do

    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
    let(:effective_on) { current_effective_date }
    let(:hired_on) { TimeKeeper.date_of_record - 3.months }
    let(:employee_created_at) { hired_on }
    let(:employee_updated_at) { employee_created_at }

    let(:person) {FactoryBot.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789')}


    let!(:sponsored_benefit) {benefit_sponsorship.benefit_applications.first.benefit_packages.first.health_sponsored_benefit}
    let!(:update_sponsored_benefit) {sponsored_benefit.update_attributes(product_package_kind: :single_product)}

    let(:aasm_state) { :active }
    let(:census_employee) { create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, benefit_sponsors_employer_profile_id: benefit_sponsorship.profile.id, benefit_group: current_benefit_package, hired_on: hired_on, created_at: employee_created_at, updated_at: employee_updated_at) }
    let!(:family) {
      person = FactoryBot.create(:person, last_name: census_employee.last_name, first_name: census_employee.first_name)
      employee_role = FactoryBot.create(:employee_role, person: person, census_employee: census_employee, benefit_sponsors_employer_profile_id: abc_profile.id)
      census_employee.update_attributes({employee_role: employee_role})
      Family.find_or_build_from_employee_role(employee_role)
    }

    let!(:employee_role){census_employee.employee_role}

    let(:enrollment_kind) { "open_enrollment" }
    let(:special_enrollment_period_id) { nil }

    let(:covered_individuals) { family.family_members }
    let(:person) { family.primary_applicant.person }

    let!(:enrollment) { FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                                               enrollment_members: covered_individuals,
                                               household: family.latest_household,
                                               coverage_kind: "health",
                                               family: family,
                                               effective_on: effective_on,
                                               enrollment_kind: enrollment_kind,
                                               kind: "employer_sponsored",
                                               benefit_sponsorship_id: benefit_sponsorship.id,
                                               sponsored_benefit_package_id: current_benefit_package.id,
                                               sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                                               employee_role_id: employee_role.id,
                                               product: sponsored_benefit.reference_product,
                                               benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)
    }

    before do
      census_employee.terminate_employment(effective_on + 1.days)
      enrollment.reload
      census_employee.reload
    end

    context 'when enrollment reinstated', dbclean: :around_each do

      let(:reinstated_enrollment) {
        Enrollments::Replicator::Reinstatement.new(enrollment, enrollment.terminated_on.next_day).build
      }

      it "should build reinstated enrollment" do
        expect(reinstated_enrollment.kind).to eq enrollment.kind
        expect(reinstated_enrollment.coverage_kind).to eq enrollment.coverage_kind
        expect(reinstated_enrollment.product_id).to eq enrollment.product_id
      end

      it 'should build a continuous coverage' do
        expect(reinstated_enrollment.effective_on).to eq enrollment.terminated_on.next_day
      end

      it 'should give same member coverage begin date as base enrollment to calculate premious correctly' do
        enrollment_member = reinstated_enrollment.hbx_enrollment_members.first
        expect(enrollment_member.coverage_start_on).to eq enrollment.effective_on
        expect(enrollment_member.eligibility_date).to eq reinstated_enrollment.effective_on
        expect(reinstated_enrollment.hbx_enrollment_members.size).to eq enrollment.hbx_enrollment_members.size
      end
    end
  end

  describe "renewing employer",  dbclean: :around_each do
    context "enrollment reinstate effective date" do

      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup renewal application"

      let(:predecessor_application_catalog) { true }
      let(:renewal_state) { :enrollment_open }

      let(:effective_on) { current_effective_date }
      let(:renewal_effective_date) { TimeKeeper.date_of_record.next_month.beginning_of_month }
      let!(:renewal_benefit_package) { renewal_application.benefit_packages.first }
      let!(:renewal_sponsored_benefit) { renewal_benefit_package.health_sponsored_benefit }

      let(:hired_on) { TimeKeeper.date_of_record - 3.months }
      let(:employee_created_at) { hired_on }
      let(:employee_updated_at) { employee_created_at }

      let(:person) {FactoryBot.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789')}


      let!(:sponsored_benefit) {benefit_sponsorship.benefit_applications.where(aasm_state: :active).first.benefit_packages.first.health_sponsored_benefit}
      let!(:update_sponsored_benefit) {
        sponsored_benefit.product_package_kind = :single_product
        sponsored_benefit.reference_product.renewal_product = renewal_sponsored_benefit.reference_product
        sponsored_benefit.save
        renewal_sponsored_benefit.update_attributes(product_package_kind: :single_product)
        renewal_sponsored_benefit.sponsor_contribution.contribution_levels.each do |level|
          level.contribution_unit_id = renewal_sponsored_benefit.contribution_model.contribution_units.where(display_name: level.display_name).first.id
          level.save
        end
      }

      let(:aasm_state) { :active }
      let(:census_employee) { create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, benefit_sponsors_employer_profile_id: benefit_sponsorship.profile.id, benefit_group: current_benefit_package, hired_on: hired_on, created_at: employee_created_at, updated_at: employee_updated_at) }
      let!(:family) {
        person = FactoryBot.create(:person, last_name: census_employee.last_name, first_name: census_employee.first_name)
        employee_role = FactoryBot.create(:employee_role, person: person, census_employee: census_employee, benefit_sponsors_employer_profile_id: abc_profile.id)
        census_employee.update_attributes({employee_role: employee_role})
        Family.find_or_build_from_employee_role(employee_role)
      }

      let!(:employee_role){census_employee.employee_role}

      let(:enrollment_kind) { "open_enrollment" }
      let(:special_enrollment_period_id) { nil }

      let(:covered_individuals) { family.family_members }
      let(:person) { family.primary_applicant.person }

      let!(:enrollment) { FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                                            enrollment_members: covered_individuals,
                                            household: family.latest_household,
                                            coverage_kind: "health",
                                            family: family,
                                            effective_on: effective_on,
                                            enrollment_kind: enrollment_kind,
                                            kind: "employer_sponsored",
                                            benefit_sponsorship_id: benefit_sponsorship.id,
                                            sponsored_benefit_package_id: current_benefit_package.id,
                                            sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                                            employee_role_id: employee_role.id,
                                            product: sponsored_benefit.reference_product,
                                            benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)
      }

      context "prior to renewing plan year begin date" do
        let(:reinstate_effective_date) { renewal_effective_date.prev_month }

        let(:reinstated_enrollment) {
          enrollment.reinstate(edi: false)
        }

        before do
          census_employee.terminate_employment(reinstate_effective_date.prev_day)
          enrollment.reload
          census_employee.reload
        end

        it "should build reinstated enrollment" do
          expect(reinstated_enrollment.kind).to eq enrollment.kind
          expect(reinstated_enrollment.coverage_kind).to eq enrollment.coverage_kind
          expect(reinstated_enrollment.product_id).to eq enrollment.product_id
        end

        it 'should build a continuous coverage' do
          expect(reinstated_enrollment.effective_on).to eq enrollment.terminated_on.next_day
        end

        it 'should give same member coverage begin date as base enrollment to calculate premious correctly' do
          enrollment_member = reinstated_enrollment.hbx_enrollment_members.first
          expect(enrollment_member.coverage_start_on).to eq enrollment.effective_on
          expect(enrollment_member.eligibility_date).to eq reinstated_enrollment.effective_on
          expect(reinstated_enrollment.hbx_enrollment_members.size).to eq enrollment.hbx_enrollment_members.size
        end

        it "should generate passive renewal" do
          initial_benefit_package = renewal_application.predecessor.benefit_packages.first
          renewal_application.benefit_packages.first.update_attributes(title: initial_benefit_package.title + "(#{renewal_application.effective_period.min.year})")
          reinstated_enrollment
          enrollment = HbxEnrollment.where({ family_id:family.id,
                                             :effective_on => renewal_effective_date,
                                             :aasm_state.ne => 'coverage_canceled'
                                           }).first
          expect(enrollment.present?).to be_truthy

          expect(enrollment.sponsored_benefit_package.benefit_application).to eq benefit_sponsorship.renewal_benefit_application
        end
      end

      context "same as renewing plan year begin date" do
        let(:reinstate_effective_date) { renewal_effective_date }

        context "when plan year is renewing" do
          let(:reinstated_enrollment) { enrollment.reinstate(edi: false) }

          before do
            enrollment.terminate_coverage!(reinstate_effective_date.prev_day)
            enrollment.reload
            census_employee.reload
          end

          it "should build reinstated enrollment" do
            expect(reinstated_enrollment.kind).to eq enrollment.kind
            expect(reinstated_enrollment.coverage_kind).to eq enrollment.coverage_kind
          end

          it "should generate reinstated enrollment with next plan year" do
            expect(reinstated_enrollment.effective_on).to eq reinstate_effective_date
            expect(reinstated_enrollment.sponsored_benefit_package.benefit_application).to eq benefit_sponsorship.renewal_benefit_application
            expect(reinstated_enrollment.product_id).to eq renewal_benefit_package.health_sponsored_benefit.reference_product.id
          end

          it 'should build a continuous coverage' do
            expect(reinstated_enrollment.effective_on).to eq enrollment.terminated_on.next_day
          end

          it 'should give same member coverage begin date as base enrollment to calculate premious correctly' do
            enrollment_member = reinstated_enrollment.hbx_enrollment_members.first
            expect(enrollment_member.coverage_start_on).to eq reinstated_enrollment.effective_on
            expect(enrollment_member.eligibility_date).to eq reinstated_enrollment.effective_on
            expect(reinstated_enrollment.hbx_enrollment_members.size).to eq enrollment.hbx_enrollment_members.size
          end

          it "should not generate any other passive renewal" do
            reinstated_enrollment
            enrollment = HbxEnrollment.where({family_id:family.id,
                                              :effective_on => renewal_effective_date,
                                              :aasm_state.ne => 'coverage_canceled'
                                             }).detect{|en| en != reinstated_enrollment}
            expect(enrollment).to be_nil
          end
        end

        context "when renewal plan year is already active" do
          let(:reinstated_enrollment) { enrollment.reinstate(edi: false) }

          before do
            TimeKeeper.set_date_of_record_unprotected!(renewal_effective_date + 5.days)
            benefit_sponsorship.benefit_applications.where(aasm_state: :active).first.update(aasm_state: :expired)
            renewal_application.update(aasm_state: :active)
            benefit_sponsorship.reload
            census_employee.benefit_sponsorship.reload
            census_employee.terminate_employment(reinstate_effective_date.prev_day)
            enrollment.reload
            census_employee.reload
          end

          after do
            TimeKeeper.set_date_of_record_unprotected!(Date.today)
          end

          it "should build reinstated enrollment" do
            expect(reinstated_enrollment.kind).to eq enrollment.kind
            expect(reinstated_enrollment.coverage_kind).to eq enrollment.coverage_kind
          end

          it "should generate reinstated enrollment with next plan year" do
            expect(reinstated_enrollment.effective_on).to eq reinstate_effective_date
            expect(reinstated_enrollment.sponsored_benefit_package.benefit_application).to eq benefit_sponsorship.active_benefit_application
            expect(reinstated_enrollment.product_id).to eq renewal_benefit_package.health_sponsored_benefit.reference_product.id
          end

          it 'should build a continuous coverage' do
            expect(reinstated_enrollment.effective_on).to eq enrollment.terminated_on.next_day
          end

          it 'should give same member coverage begin date as base enrollment to calculate premious correctly' do
            enrollment_member = reinstated_enrollment.hbx_enrollment_members.first
            expect(enrollment_member.coverage_start_on).to eq reinstated_enrollment.effective_on
            expect(enrollment_member.eligibility_date).to eq reinstated_enrollment.effective_on
            expect(reinstated_enrollment.hbx_enrollment_members.size).to eq enrollment.hbx_enrollment_members.size
          end

          it "should not generate any other passive renewal" do
            reinstated_enrollment
            enrollment = HbxEnrollment.where({family_id:family.id,
                                                    :effective_on => renewal_effective_date,
                                                    :aasm_state.ne => 'coverage_canceled'
                                                   }).detect{|en| en != reinstated_enrollment}
            expect(enrollment).to be_nil
          end
        end
      end
    end
  end
end