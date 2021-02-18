# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe Operations::HbxEnrollments::Reinstate, :type => :model, dbclean: :around_each do
  describe 'reinstate enrollment',  dbclean: :around_each do
    include_context 'setup benefit market with market catalogs and product packages'
    include_context 'setup initial benefit application'

    let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month - 6.months }
    let(:effective_on) { current_effective_date }
    let(:hired_on) { TimeKeeper.date_of_record - 3.months }
    let(:employee_created_at) { hired_on }
    let(:employee_updated_at) { employee_created_at }
    let(:person) {FactoryBot.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789')}
    let!(:benefit_package) {benefit_sponsorship.benefit_applications.first.benefit_packages.first}
    let!(:sponsored_benefit) {benefit_sponsorship.benefit_applications.first.benefit_packages.first.health_sponsored_benefit}
    let!(:update_sponsored_benefit) {sponsored_benefit.update_attributes(product_package_kind: :single_product)}
    let(:aasm_state) { :active }
    let(:census_employee) do
      create(:census_employee,
             :with_active_assignment,
             benefit_sponsorship: benefit_sponsorship,
             benefit_sponsors_employer_profile_id: benefit_sponsorship.profile.id,
             benefit_group: current_benefit_package,
             hired_on: hired_on,
             created_at: employee_created_at,
             updated_at: employee_updated_at)
    end
    let!(:family) do
      person = FactoryBot.create(:person, last_name: census_employee.last_name, first_name: census_employee.first_name)
      employee_role = FactoryBot.create(:employee_role, person: person, census_employee: census_employee, benefit_sponsors_employer_profile_id: abc_profile.id)
      census_employee.update_attributes({employee_role: employee_role})
      Family.find_or_build_from_employee_role(employee_role)
    end
    let!(:employee_role){census_employee.employee_role}
    let(:enrollment_kind) { 'open_enrollment' }
    let(:special_enrollment_period_id) { nil }
    let(:covered_individuals) { family.family_members }
    let(:person) { family.primary_applicant.person }
    let!(:glue_event_queue_name) { "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler" }
    let!(:enrollment) do
      FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                        enrollment_members: covered_individuals,
                        household: family.latest_household,
                        coverage_kind: 'health',
                        family: family,
                        effective_on: effective_on,
                        enrollment_kind: enrollment_kind,
                        kind: 'employer_sponsored',
                        benefit_sponsorship_id: benefit_sponsorship.id,
                        sponsored_benefit_package_id: current_benefit_package.id,
                        sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                        employee_role_id: employee_role.id,
                        terminate_reason: 'non_payment',
                        product: sponsored_benefit.reference_product,
                        rating_area_id: BSON::ObjectId.new,
                        benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)
    end

    context 'when enrollment reinstated', dbclean: :around_each do
      before do
        period = initial_application.effective_period.min..TimeKeeper.date_of_record.end_of_month
        initial_application.update_attributes!(termination_reason: 'nonpayment', terminated_on: period.max, effective_period: period)
        initial_application.terminate_enrollment!
        effective_period = (initial_application.effective_period.max.next_day)..(initial_application.benefit_sponsor_catalog.effective_period.max)
        cloned_application = ::BenefitSponsors::Operations::BenefitApplications::Clone.new.call({benefit_application: initial_application, effective_period: effective_period}).success
        cloned_catalog = ::BenefitMarkets::Operations::BenefitSponsorCatalogs::Clone.new.call(benefit_sponsor_catalog: initial_application.benefit_sponsor_catalog).success
        cloned_catalog.benefit_application = cloned_application
        cloned_catalog.save!
        cloned_application.assign_attributes({aasm_state: :active, reinstated_id: initial_application.id, benefit_sponsor_catalog_id: cloned_catalog.id})
        cloned_application.save!
        @cloned_package = cloned_application.benefit_packages[0]
        census_employee.reload
        enrollment.reload
      end
      let!(:new_bga) do
        ::Operations::BenefitGroupAssignments::Reinstate.new.call({benefit_group_assignment: census_employee.benefit_group_assignments.first, options: {benefit_package: @cloned_package} })
        census_employee.benefit_group_assignments.where(start_on:  @cloned_package.start_on).first
      end

      context 'for a terminated enrollment' do
        before do
          @reinstated_enrollment = subject.call({hbx_enrollment: enrollment, options: {benefit_package: new_bga.benefit_package}}).success
        end

        it 'should build reinstated enrollment' do
          expect(@reinstated_enrollment.kind).to eq enrollment.kind
          expect(@reinstated_enrollment.coverage_kind).to eq enrollment.coverage_kind
          expect(@reinstated_enrollment.product_id).to eq enrollment.product_id
        end

        it 'should return enrollment in coverage_selected state' do
          expect(@reinstated_enrollment.aasm_state).to eq 'coverage_selected'
        end

        it 'should assign benefit group assignment' do
          expect(@reinstated_enrollment.benefit_group_assignment).to eq new_bga
        end

        it 'should set parent enrollment' do
          expect(@reinstated_enrollment.parent_enrollment).to eq enrollment
        end

        it 'reinstated enrollment should have new hbx id' do
          expect(@reinstated_enrollment.hbx_id).not_to eq enrollment.hbx_id
        end

        it 'should have continuous coverage' do
          expect(@reinstated_enrollment.effective_on).to eq enrollment.terminated_on.next_day
        end

        it 'should give same member coverage begin date as base enrollment' do
          enrollment_member = @reinstated_enrollment.hbx_enrollment_members.first
          expect(enrollment_member.coverage_start_on).to eq enrollment.effective_on
          expect(enrollment_member.eligibility_date).to eq @reinstated_enrollment.effective_on
          expect(@reinstated_enrollment.hbx_enrollment_members.size).to eq enrollment.hbx_enrollment_members.size
        end
      end

      context "should trigger enrollment event" do
        it 'publish amqp message' do
          expect_any_instance_of(HbxEnrollment).to receive(:notify)
          @reinstated_enrollment = subject.call({hbx_enrollment: enrollment, options: {benefit_package: new_bga.benefit_package}}).success
        end
      end

      context 'terminated enrollment, employee future terminated ' do
        before do
          census_employee.terminate_employment(TimeKeeper.date_of_record.next_month.end_of_month)
          @reinstated_enrollment = subject.call({hbx_enrollment: enrollment, options: {benefit_package: new_bga.benefit_package}}).success
          @reinstated_enrollment.reload
        end

        it 'should build reinstated enrollment' do
          expect(@reinstated_enrollment.kind).to eq enrollment.kind
          expect(@reinstated_enrollment.coverage_kind).to eq enrollment.coverage_kind
          expect(@reinstated_enrollment.product_id).to eq enrollment.product_id
        end

        it 'should return enrollment in coverage_termination_pending state' do
          expect(@reinstated_enrollment.aasm_state).to eq 'coverage_termination_pending'
        end

        it 'should set terminated date on enrollment' do
          expect(@reinstated_enrollment.terminated_on).to eq census_employee.employment_terminated_on
        end

        it 'should assign benefit group assignment' do
          expect(@reinstated_enrollment.benefit_group_assignment).to eq new_bga
        end

        it 'reinstated enrollment should have new hbx id' do
          expect(@reinstated_enrollment.hbx_id).not_to eq enrollment.hbx_id
        end

        it 'should have continuous coverage' do
          expect(@reinstated_enrollment.effective_on).to eq enrollment.terminated_on.next_day
        end

        it 'should give same member coverage begin date as base enrollment' do
          enrollment_member = @reinstated_enrollment.hbx_enrollment_members.first
          expect(enrollment_member.coverage_start_on).to eq enrollment.effective_on
          expect(enrollment_member.eligibility_date).to eq @reinstated_enrollment.effective_on
          expect(@reinstated_enrollment.hbx_enrollment_members.size).to eq enrollment.hbx_enrollment_members.size
        end
      end

      context 'for a waived enrollment' do
        before do
          enrollment.update_attributes!(effective_on: @cloned_package.start_on, aasm_state: 'shopping', terminate_reason: 'retroactive_canceled')
          enrollment.waive_coverage!
          enrollment.cancel_coverage!
          @result = subject.call({hbx_enrollment: enrollment, options: {benefit_package: new_bga.benefit_package}}).success
        end

        it 'should transition to inactive' do
          expect(@result.aasm_state).to eq('inactive')
        end
      end
    end

    context 'reinstating terminated enrollment, employee terminated in past', dbclean: :after_each do
      before do
        period = initial_application.effective_period.min..(TimeKeeper.date_of_record - 2.months).end_of_month
        initial_application.update_attributes!(termination_reason: 'nonpayment', terminated_on: period.max, effective_period: period)
        initial_application.terminate_enrollment!
        census_employee.terminate_employment(TimeKeeper.date_of_record.last_month.end_of_month)

        effective_period = (initial_application.effective_period.max.next_day)..(initial_application.benefit_sponsor_catalog.effective_period.max)
        cloned_application = ::BenefitSponsors::Operations::BenefitApplications::Clone.new.call({benefit_application: initial_application, effective_period: effective_period}).success
        cloned_catalog = ::BenefitMarkets::Operations::BenefitSponsorCatalogs::Clone.new.call(benefit_sponsor_catalog: initial_application.benefit_sponsor_catalog).success
        cloned_catalog.benefit_application = cloned_application
        cloned_catalog.save!
        cloned_application.assign_attributes({aasm_state: :active, reinstated_id: initial_application.id, benefit_sponsor_catalog_id: cloned_catalog.id})
        cloned_application.save!
        @cloned_package = cloned_application.benefit_packages[0]
        census_employee.reload
        enrollment.reload
      end
      let!(:new_bga) do
        ::Operations::BenefitGroupAssignments::Reinstate.new.call({benefit_group_assignment: census_employee.benefit_group_assignments.first, options: {benefit_package: @cloned_package} })
        census_employee.benefit_group_assignments.where(start_on:  @cloned_package.start_on).first
      end

      before do
        @reinstated_enrollment = subject.call({hbx_enrollment: enrollment, options: {benefit_package: new_bga.benefit_package}}).success
        @reinstated_enrollment.reload
      end

      it 'should build reinstated enrollment' do
        expect(@reinstated_enrollment.kind).to eq enrollment.kind
        expect(@reinstated_enrollment.coverage_kind).to eq enrollment.coverage_kind
        expect(@reinstated_enrollment.product_id).to eq enrollment.product_id
      end

      it 'should return enrollment in coverage_termination_pending state' do
        expect(@reinstated_enrollment.aasm_state).to eq 'coverage_terminated'
      end

      it 'should set terminated date on enrollment' do
        expect(@reinstated_enrollment.terminated_on).to eq census_employee.employment_terminated_on.end_of_month
      end

      it 'should assign benefit group assignment' do
        expect(@reinstated_enrollment.benefit_group_assignment).to eq new_bga
      end

      it 'reinstated enrollment should have new hbx id' do
        expect(@reinstated_enrollment.hbx_id).not_to eq enrollment.hbx_id
      end

      it 'should have continuous coverage' do
        expect(@reinstated_enrollment.effective_on).to eq enrollment.terminated_on.next_day
      end

      it 'should give same member coverage begin date as base enrollment' do
        enrollment_member = @reinstated_enrollment.hbx_enrollment_members.first
        expect(enrollment_member.coverage_start_on).to eq enrollment.effective_on
        expect(enrollment_member.eligibility_date).to eq @reinstated_enrollment.effective_on
        expect(@reinstated_enrollment.hbx_enrollment_members.size).to eq enrollment.hbx_enrollment_members.size
      end
    end

    context 'when benefit group assignment not found', dbclean: :after_each do
      before do
        period = initial_application.effective_period.min..TimeKeeper.date_of_record.end_of_month
        initial_application.update_attributes!(termination_reason: 'nonpayment', terminated_on: period.max, effective_period: period)
        initial_application.terminate_enrollment!
        effective_period = (initial_application.effective_period.max.next_day)..(initial_application.benefit_sponsor_catalog.effective_period.max)
        cloned_application = ::BenefitSponsors::Operations::BenefitApplications::Clone.new.call({benefit_application: initial_application, effective_period: effective_period}).success
        cloned_catalog = ::BenefitMarkets::Operations::BenefitSponsorCatalogs::Clone.new.call(benefit_sponsor_catalog: initial_application.benefit_sponsor_catalog).success
        cloned_catalog.benefit_application = cloned_application
        cloned_catalog.save!
        cloned_application.assign_attributes({aasm_state: :active, reinstated_id: initial_application.id, benefit_sponsor_catalog_id: cloned_catalog.id})
        cloned_application.save!
        @cloned_package = cloned_application.benefit_packages[0]
        census_employee.reload
        enrollment.reload
        @result = subject.call({hbx_enrollment: enrollment, options: {benefit_package: @cloned_package}})
      end

      it 'should return a failure with a message' do
        expect(@result.failure).to eq("Active Benefit Group Assignment does not exist for the effective_on: #{enrollment.terminated_on.next_day}")
      end
    end

    context 'overlapping enrollment exists' do
      before do
        period = initial_application.effective_period.min..TimeKeeper.date_of_record.end_of_month
        initial_application.update_attributes!(termination_reason: 'nonpayment', terminated_on: period.max, effective_period: period)
        initial_application.terminate_enrollment!
        effective_period = (initial_application.effective_period.max.next_day)..(initial_application.benefit_sponsor_catalog.effective_period.max)
        cloned_application = ::BenefitSponsors::Operations::BenefitApplications::Clone.new.call({benefit_application: initial_application, effective_period: effective_period}).success
        cloned_catalog = ::BenefitMarkets::Operations::BenefitSponsorCatalogs::Clone.new.call(benefit_sponsor_catalog: initial_application.benefit_sponsor_catalog).success
        cloned_catalog.benefit_application = cloned_application
        cloned_catalog.save!
        cloned_application.assign_attributes({aasm_state: :active, reinstated_id: initial_application.id, benefit_sponsor_catalog_id: cloned_catalog.id})
        cloned_application.save!
        @cloned_package = cloned_application.benefit_packages[0]
        census_employee.reload
        enrollment.reload
      end

      let!(:new_bga) do
        ::Operations::BenefitGroupAssignments::Reinstate.new.call({benefit_group_assignment: census_employee.benefit_group_assignments.first, options: {benefit_package: @cloned_package} })
        census_employee.benefit_group_assignments.where(start_on:  @cloned_package.start_on).first
      end

      before do
        subject.call({hbx_enrollment: enrollment, options: {benefit_package: new_bga.benefit_package}}).success
        @result = subject.call({hbx_enrollment: enrollment, options: {benefit_package: new_bga.benefit_package}})
      end

      it 'should return a failure with a message' do
        expect(@result.failure).to eq('Overlapping coverage exists for this family in current year.')
      end
    end

    context 'when benefit package optional params missing' do
      before do
        period = initial_application.effective_period.min..TimeKeeper.date_of_record.end_of_month
        initial_application.update_attributes!(termination_reason: 'nonpayment', terminated_on: period.max, effective_period: period)
        initial_application.terminate_enrollment!
        effective_period = (initial_application.effective_period.max.next_day)..(initial_application.benefit_sponsor_catalog.effective_period.max)
        cloned_application = ::BenefitSponsors::Operations::BenefitApplications::Clone.new.call({benefit_application: initial_application, effective_period: effective_period}).success
        cloned_catalog = ::BenefitMarkets::Operations::BenefitSponsorCatalogs::Clone.new.call(benefit_sponsor_catalog: initial_application.benefit_sponsor_catalog).success
        cloned_catalog.benefit_application = cloned_application
        cloned_catalog.save!
        cloned_application.assign_attributes({aasm_state: :active, reinstated_id: initial_application.id, benefit_sponsor_catalog_id: cloned_catalog.id})
        cloned_application.save!
        @cloned_package = cloned_application.benefit_packages[0]
        census_employee.reload
        enrollment.reload
        @result = subject.call({hbx_enrollment: enrollment})
      end

      it 'should return a failure with a message' do
        expect(@result.failure).to eq('Missing benefit package.')
      end
    end

    context 'when benefit package optional params missing' do
      before do
        enrollment.terminate_coverage!
        allow(enrollment).to receive(:is_shop?).and_return(false)
        @result = subject.call({hbx_enrollment: enrollment})
      end

      it 'should return a failure with a message' do
        expect(@result.failure).to eq('Not a SHOP enrollment.')
      end
    end

    context "reinstate canceled enrollment based on workflow state transitions" do
      before do
        application = benefit_package.benefit_application
        application.cancel!
        enrollment.reload
        enrollment.update_attributes(terminate_reason: '')
        reinstated_app = BenefitSponsors::Operations::BenefitApplications::Reinstate.new.call({params: {benefit_application: application}}).success
        reinstated_package = reinstated_app.benefit_packages.first
        census_employee.reload
        @reinstated_enrollment = HbxEnrollment.where(sponsored_benefit_package_id: reinstated_package.id, effective_on: reinstated_app.start_on).first
        @new_bga = census_employee.benefit_group_assignments.by_benefit_package(reinstated_package).detect{ |bga| bga.is_active?(reinstated_package.start_on)}
      end

      it 'should build reinstated enrollment' do
        expect(@reinstated_enrollment.kind).to eq enrollment.kind
        expect(@reinstated_enrollment.coverage_kind).to eq enrollment.coverage_kind
        expect(@reinstated_enrollment.product_id).to eq enrollment.product_id
      end

      it 'should return enrollment in coverage_selected state' do
        expect(@reinstated_enrollment.aasm_state).to eq 'coverage_enrolled'
      end

      it 'should assign benefit group assignment' do
        expect(@reinstated_enrollment.benefit_group_assignment).to eq @new_bga
      end

      it 'reinstated enrollment should have new hbx id' do
        expect(@reinstated_enrollment.hbx_id).not_to eq enrollment.hbx_id
      end

      it 'should have continuous coverage' do
        expect(@reinstated_enrollment.effective_on).to eq enrollment.effective_on
      end

      it 'should give same member coverage begin date as base enrollment' do
        enrollment_member = @reinstated_enrollment.hbx_enrollment_members.first
        expect(enrollment_member.coverage_start_on).to eq enrollment.effective_on
        expect(enrollment_member.eligibility_date).to eq @reinstated_enrollment.effective_on
        expect(@reinstated_enrollment.hbx_enrollment_members.size).to eq enrollment.hbx_enrollment_members.size
      end
    end
  end

  describe 'age_off_dependents', dbclean: :after_each do
    include_context 'setup benefit market with market catalogs and product packages'
    include_context 'setup initial benefit application'
    let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year - 6.months  }
    let(:benefit_package) {initial_application.benefit_packages.first}
    let!(:person) {FactoryBot.create(:person, :with_employee_role)}
    let!(:family) {FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person)}
    let!(:family_member1) {family.family_members.first}
    let!(:family_member2) {family.family_members.second}
    let!(:family_member3) {family.family_members.last}
    let!(:census_employee) do
      create(:census_employee,
             :with_active_assignment,
             benefit_sponsorship: benefit_sponsorship,
             benefit_sponsors_employer_profile_id: benefit_sponsorship.profile.id,
             benefit_group: benefit_package,
             hired_on: TimeKeeper.date_of_record.prev_year - 3.months)
    end
    let!(:employee_role) {FactoryBot.create(:employee_role, person: person, census_employee: census_employee, benefit_sponsors_employer_profile_id: abc_profile.id)}
    let(:enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        household: family.latest_household,
                        coverage_kind: "health",
                        family: family,
                        kind: "employer_sponsored",
                        effective_on: initial_application.start_on,
                        benefit_sponsorship_id: benefit_sponsorship.id,
                        sponsored_benefit_package_id: benefit_package.id,
                        sponsored_benefit_id: benefit_package.sponsored_benefits[0].id,
                        product: benefit_package.sponsored_benefits[0].reference_product,
                        employee_role_id: employee_role.id,
                        rating_area_id: BSON::ObjectId.new)
    end
    let!(:enr_mem1) { FactoryBot.create(:hbx_enrollment_member, applicant_id: family_member1.id, is_subscriber: family_member1.is_primary_applicant, hbx_enrollment: enrollment) }
    let!(:enr_mem2) { FactoryBot.create(:hbx_enrollment_member, applicant_id: family_member2.id, is_subscriber: family_member2.is_primary_applicant, hbx_enrollment: enrollment) }
    let!(:enr_mem3) { FactoryBot.create(:hbx_enrollment_member, applicant_id: family_member3.id, is_subscriber: family_member3.is_primary_applicant, hbx_enrollment: enrollment) }


    context 'monthly ageoff termination' do
      before do
        period = (initial_application.effective_period.min..initial_application.start_on.next_month.end_of_month)
        initial_application.update_attributes!(termination_reason: 'nonpayment', terminated_on: period.max, effective_period: period)
        initial_application.terminate_enrollment!
        effective_period = (initial_application.effective_period.max.next_day)..(initial_application.benefit_sponsor_catalog.effective_period.max)
        cloned_application = ::BenefitSponsors::Operations::BenefitApplications::Clone.new.call({benefit_application: initial_application, effective_period: effective_period}).success
        cloned_catalog = ::BenefitMarkets::Operations::BenefitSponsorCatalogs::Clone.new.call(benefit_sponsor_catalog: initial_application.benefit_sponsor_catalog).success

        cloned_catalog.benefit_application = cloned_application
        cloned_catalog.save!
        cloned_application.assign_attributes({reinstated_id: initial_application.id, benefit_sponsor_catalog_id: cloned_catalog.id})
        cloned_application.save!

        @cloned_package = cloned_application.benefit_packages[0]
        @cloned_package.reinstate_member_benefits
        census_employee.reload

        @cloned_package.reinstate_benefit_group_assignment(census_employee.benefit_group_assignments.first)
        enr_mem2.person.update_attributes(dob: cloned_application.start_on - 26.years)
        enr_mem3.person.update_attributes(dob: cloned_application.start_on.next_month - 26.years)
        enrollment.reload
      end

      context 'shop market', dbclean: :after_each do
        before do
          allow(::EnrollRegistry[:aca_shop_dependent_age_off].settings[0]).to receive(:item).and_return(:monthly)
        end

        it 'should create new enrollment' do
          family = enrollment.family
          expect(family.hbx_enrollments.count).to eq 1
          subject.call({hbx_enrollment: enrollment, options: {benefit_package: @cloned_package}})
          enrollment.reload
          expect(family.hbx_enrollments.count).to eq 4
        end

        it 'should drop dependents who are > 26 and create a new enrollment' do
          family = enrollment.family
          expect(family.hbx_enrollments.coverage_enrolled.count).to eq 0
          subject.call({hbx_enrollment: enrollment, options: {benefit_package: @cloned_package}})
          enrollment.reload
          expect(family.hbx_enrollments.coverage_enrolled.count).to eq 1
          expect(family.hbx_enrollments.coverage_enrolled.first.hbx_enrollment_members.count).to eq 1
        end

        context 'census employee in terminated status' do

          context "before reinstatement dependent aged off 26" do
            # 1.  should cancel reinstated enrollment.
            # 2. should create new ageoff reinstated enrollment without ageoff dependent and
            # 3. should terminate ageoff reinstated enrollment with employment date.
            before do
              allow(::EnrollRegistry[:aca_shop_dependent_age_off].settings[0]).to receive(:item).and_return(:monthly)
              census_employee.employment_terminated_on = @cloned_package.start_on.end_of_month
              census_employee.save(validate: false)
              census_employee.reload
              enr_mem2.person.update_attributes(dob: @cloned_package.start_on.prev_day - 26.years)
              enr_mem3.person.update_attributes(dob: @cloned_package.start_on.next_month - 26.years)
              enrollment.reload
            end

            it 'should create new enrollment' do
              family = enrollment.family
              expect(family.hbx_enrollments.count).to eq 1
              subject.call({hbx_enrollment: enrollment, options: {benefit_package: @cloned_package}})
              enrollment.reload
              expect(family.hbx_enrollments.map(&:aasm_state)).to eq ["coverage_terminated", "coverage_canceled", "coverage_terminated"]
              expect(family.hbx_enrollments.count).to eq 3
            end

            it "should terminate enrollment with employment termination date" do
              family = enrollment.family
              subject.call({hbx_enrollment: enrollment, options: {benefit_package: @cloned_package}})
              enrollment.reload
              expect(family.hbx_enrollments.where(terminated_on: census_employee.employment_terminated_on.end_of_month).count).to eq 1
            end
          end

          context "after reinstatement dependent aged off 26" do
            # 1.  should terminated reinstated enrollment when dependent age passed 26
            # 2. should create new ageoff reinstated enrollment without ageoff dependent and
            # 3. should terminate ageoff reinstated enrollment with employment date.
            before do
              allow(::EnrollRegistry[:aca_shop_dependent_age_off].settings[0]).to receive(:item).and_return(:monthly)
              census_employee.employment_terminated_on = @cloned_package.start_on.next_month.end_of_month
              census_employee.save(validate: false)
              census_employee.reload
              enr_mem2.person.update_attributes(dob: @cloned_package.start_on - 26.years)
              enr_mem3.person.update_attributes(dob: @cloned_package.start_on.next_month - 26.years)
              enrollment.reload
            end

            it 'should create new enrollment' do
              family = enrollment.family
              expect(family.hbx_enrollments.count).to eq 1
              subject.call({hbx_enrollment: enrollment, options: {benefit_package: @cloned_package}})
              enrollment.reload
              expect(family.hbx_enrollments.map(&:aasm_state)).to eq ["coverage_terminated", "coverage_terminated", "coverage_terminated"]
              expect(family.hbx_enrollments.count).to eq 3
            end

            it "should terminate enrollment with employment termination date" do
              family = enrollment.family
              subject.call({hbx_enrollment: enrollment, options: {benefit_package: @cloned_package}})
              enrollment.reload
              expect(family.hbx_enrollments.where(terminated_on: census_employee.employment_terminated_on.end_of_month).count).to eq 1
            end
          end

        end
      end

      context 'fehb market', dbclean: :after_each do

        before do
          allow_any_instance_of(HbxEnrollment).to receive(:fehb_profile).and_return(true)
        end

        it 'should create new enrollment' do
          family = enrollment.family
          expect(family.hbx_enrollments.count).to eq 1
          subject.call({hbx_enrollment: enrollment, options: {benefit_package: @cloned_package}})
          enrollment.reload
          expect(family.hbx_enrollments.count).to eq 4
        end

        it 'should drop dependents who are > 26 and create a new enrollment' do
          family = enrollment.family
          expect(family.hbx_enrollments.coverage_enrolled.count).to eq 0
          subject.call({hbx_enrollment: enrollment, options: {benefit_package: @cloned_package}})
          enrollment.reload
          expect(family.hbx_enrollments.coverage_enrolled.count).to eq 1
          expect(family.hbx_enrollments.coverage_enrolled.first.hbx_enrollment_members.count).to eq 1
        end
      end
    end

    context 'yearly ageoff termination' do
      before do
        period = (initial_application.effective_period.min..initial_application.start_on.end_of_year)
        initial_application.update_attributes!(termination_reason: 'nonpayment', terminated_on: period.max, effective_period: period)
        initial_application.terminate_enrollment!
        effective_period = (initial_application.effective_period.max.next_day)..(initial_application.benefit_sponsor_catalog.effective_period.max)
        cloned_application = ::BenefitSponsors::Operations::BenefitApplications::Clone.new.call({benefit_application: initial_application, effective_period: effective_period}).success
        cloned_catalog = ::BenefitMarkets::Operations::BenefitSponsorCatalogs::Clone.new.call(benefit_sponsor_catalog: initial_application.benefit_sponsor_catalog).success

        cloned_catalog.benefit_application = cloned_application
        cloned_catalog.save!
        cloned_application.assign_attributes({reinstated_id: initial_application.id, benefit_sponsor_catalog_id: cloned_catalog.id})
        cloned_application.save!

        @cloned_package = cloned_application.benefit_packages[0]
        @cloned_package.reinstate_member_benefits
        census_employee.reload

        @cloned_package.reinstate_benefit_group_assignment(census_employee.benefit_group_assignments.first)
        enr_mem2.person.update_attributes(dob: initial_application.end_on - 26.years)
        enr_mem3.person.update_attributes(dob: cloned_application.start_on - 26.years)
        enrollment.reload

      end

      context 'shop market', dbclean: :after_each do
        before do
          allow(::EnrollRegistry[:aca_shop_dependent_age_off].settings[0]).to receive(:item).and_return(:annual)
          allow(TimeKeeper).to receive(:date_of_record).and_return(initial_application.benefit_sponsor_catalog.effective_date.next_year.beginning_of_year)
        end

        it 'should create new enrollment' do
          family = enrollment.family
          expect(family.hbx_enrollments.count).to eq 1
          subject.call({hbx_enrollment: enrollment, options: {benefit_package: @cloned_package}})
          enrollment.reload
          expect(family.hbx_enrollments.count).to eq 3
        end

        it 'should drop dependents who are > 26 and create a new enrollment' do
          family = enrollment.family
          expect(family.hbx_enrollments.coverage_enrolled.count).to eq 0
          subject.call({hbx_enrollment: enrollment, options: {benefit_package: @cloned_package}})
          enrollment.reload
          expect(family.hbx_enrollments.coverage_enrolled.count).to eq 1
          expect(family.hbx_enrollments.coverage_enrolled.first.hbx_enrollment_members.count).to eq 2
        end
      end

      context 'fehb market', dbclean: :after_each do

        before do
          allow(::EnrollRegistry[:aca_fehb_dependent_age_off].settings[0]).to receive(:item).and_return(:annual)
          allow_any_instance_of(HbxEnrollment).to receive(:fehb_profile).and_return(true)
          allow(TimeKeeper).to receive(:date_of_record).and_return(initial_application.benefit_sponsor_catalog.effective_date.next_year.beginning_of_year)
        end

        it 'should create new enrollment' do
          family = enrollment.family
          expect(family.hbx_enrollments.count).to eq 1
          subject.call({hbx_enrollment: enrollment, options: {benefit_package: @cloned_package}})
          enrollment.reload
          expect(family.hbx_enrollments.count).to eq 3
        end

        it 'should drop dependents who are > 26 and create a new enrollment' do
          family = enrollment.family
          expect(family.hbx_enrollments.coverage_enrolled.count).to eq 0
          subject.call({hbx_enrollment: enrollment, options: {benefit_package: @cloned_package}})
          enrollment.reload
          expect(family.hbx_enrollments.coverage_enrolled.count).to eq 1
          expect(family.hbx_enrollments.coverage_enrolled.first.hbx_enrollment_members.count).to eq 2
        end
      end

      after do
        TimeKeeper.set_date_of_record_unprotected!(Time.zone.today)
      end
    end
  end
end
