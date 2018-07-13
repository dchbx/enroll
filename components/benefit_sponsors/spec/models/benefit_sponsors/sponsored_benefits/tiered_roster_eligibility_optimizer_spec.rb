require "rails_helper"

module BenefitSponsors
	RSpec.describe SponsoredBenefits::TieredRosterEligibilityOptimizer do
		subject { ::BenefitSponsors::SponsoredBenefits::TieredRosterEligibilityOptimizer.new }

		let(:employee_dob) { Date.new(1990, 6, 1) }
	  let(:employee_member_id) { "some_employee_id" }
		let(:roster_entry) do
			::BenefitSponsors::Members::MemberGroup.new(
        roster_members,
        group_enrollment: group_enrollment,
			)
		end
    let(:employee) do
      instance_double(
        "::BenefitMarkets::SponsoredBenefits::RosterMember",
        member_id: employee_member_id,
        relationship: "self",
        is_disabled?: false,
        is_primary_member?: true,
        dob: employee_dob
      )
    end
    let(:employee_enrollment) do
      BenefitSponsors::Enrollments::MemberEnrollment.new(
        member_id: employee_member_id
      )
    end
		let(:employee_age) { 27 }

		let(:product) { double(id: "some_product_id") }

		let(:coverage_start_date) { Date.new(2018, 1, 1) }

    let(:group_enrollment) do
      BenefitSponsors::Enrollments::GroupEnrollment.new(
        member_enrollments: member_enrollments,
        rate_schedule_date: Date.new(2018, 1, 1),
        coverage_start_on: coverage_start_date,
        previous_product: nil,
        product: product
      )
    end

		describe "given:
			- a sponsor which offers composite rating and contributions
			- with an 'employee_only' and 'family' groups (like CCA)
			- where all groups offered coverage by the sponsor" do

			let(:contribution_model) { 
        instance_double(
          ::BenefitMarkets::ContributionModels::ContributionModel,
          contribution_units: [family_contribution_unit]
        )
      }

      let(:family_contribution_unit) do
        instance_double(
          ::BenefitMarkets::ContributionModels::ContributionUnit,
          id: "contribution_unit_id"
        )
      end

			let(:sponsor_contribution) do
				instance_double(
					::BenefitSponsors::SponsoredBenefits::SponsorContribution,
					id: "a sponsor_conribution_id",
					contribution_levels: [family_contribution_level]
				)
			end

      let(:family_contribution_level) do
				instance_double(
					::BenefitSponsors::SponsoredBenefits::ContributionLevel,
          contribution_unit_id: "contribution_unit_id",
          is_offered: true
        )
      end

			describe "
				given:
					- a roster
					- with an employee
					- with a spouse
					- with a nibling
			" do


				let(:spouse_member_id) { "some_spouse_id" }
				let(:nibling_member_id) { "some_nibbling_id" }
				let(:nibling_dob) { Date.new(2015, 1, 1) }
				let(:nibling) do
					instance_double(
						"::BenefitMarkets::SponsoredBenefits::RosterMember",
						member_id: nibling_member_id,
						relationship: "nephew",
						is_disabled?: false,
						dob: nibling_dob,
            is_primary_member?: false
					)
				end
        let(:nibling_member_enrollment) do
          ::BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: nibling_member_id
          )
        end

				let(:nibling_age) { 3 }

				let(:spouse_dob) { Date.new(1995, 9, 27) }
				let(:spouse) do
					instance_double(
						"::BenefitMarkets::SponsoredBenefits::RosterMember",
						member_id: spouse_member_id,
						relationship: "spouse",
						is_disabled?: false,
						dob: spouse_dob,
            is_primary_member?: false
					)
				end
        let(:spouse_member_enrollment) do
          ::BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: spouse_member_id
          )
        end
				let(:spouse_age) { 22 }

        let(:roster_members) { [employee, spouse, nibling] }
        let(:member_enrollments) { [employee_enrollment, spouse_member_enrollment, nibling_member_enrollment] }

				before(:each) do
					allow(contribution_model).to receive(:map_relationship_for).with("self", employee_age, false).and_return("employee")
					allow(contribution_model).to receive(:map_relationship_for).with("spouse", spouse_age, false).and_return("spouse")
					allow(contribution_model).to receive(:map_relationship_for).with("nephew", nibling_age, false).and_return(nil)
          allow(family_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1}).and_return(true)
				end

				it "keeps the spouse" do
					optimized_roster_entry = subject.calculate_optimal_group_for(
						contribution_model,
						roster_entry,
						sponsor_contribution
					)
          dependent_ids = optimized_roster_entry.members.map(&:member_id)
          dependent_enrollment_ids = optimized_roster_entry.group_enrollment.member_enrollments.map(&:member_id)
          expect(dependent_ids).to include(spouse_member_id)
          expect(dependent_enrollment_ids).to include(spouse_member_id)
				end

				it "removes the roster member with the unmappable relationship" do
					optimized_roster_entry = subject.calculate_optimal_group_for(
						contribution_model,
						roster_entry,
						sponsor_contribution
					)
          dependent_ids = optimized_roster_entry.members.map(&:member_id)
          dependent_enrollment_ids = optimized_roster_entry.group_enrollment.member_enrollments.map(&:member_id)
          expect(dependent_ids).not_to include(nibling_member_id)
          expect(dependent_enrollment_ids).not_to include(nibling_member_id)
				end
			end
		end

		describe "given:
			- a sponsor which offers composite rating and contributions
			- with an 'employee_only' and 'family' groups (like CCA)
			- where only 'employee_only' is offered by the sponsor" do

			let(:contribution_model) do
        instance_double(
          ::BenefitMarkets::ContributionModels::ContributionModel,
          contribution_units: [employee_contribution_unit, family_contribution_unit]
        )
      end

      let(:employee_contribution_unit) do
        instance_double(
          ::BenefitMarkets::ContributionModels::ContributionUnit,
          id: "employee_contribution_unit_id"
        )
      end

      let(:family_contribution_unit) do
        instance_double(
          ::BenefitMarkets::ContributionModels::ContributionUnit,
          id: "contribution_unit_id"
        )
      end

			let(:sponsor_contribution) do
				instance_double(
					::BenefitSponsors::SponsoredBenefits::SponsorContribution,
					id: "a sponsor_conribution_id",
					contribution_levels: [employee_contribution_level, family_contribution_level]
				)
			end

      let(:employee_contribution_level) do
				instance_double(
					::BenefitSponsors::SponsoredBenefits::ContributionLevel,
          contribution_unit_id: "employee_contribution_unit_id",
          is_offered: true
        )
      end

      let(:family_contribution_level) do
				instance_double(
					::BenefitSponsors::SponsoredBenefits::ContributionLevel,
          contribution_unit_id: "contribution_unit_id",
          is_offered: false
        )
      end

			describe "
				given:
					- a roster
					- with an employee
					- with a spouse
			" do

				let(:spouse_member_id) { "some_spouse_id" }
				let(:spouse_dob) { Date.new(1995, 9, 27) }
				let(:spouse) do
					instance_double(
						"::BenefitMarkets::SponsoredBenefits::RosterMember",
						member_id: spouse_member_id,
						relationship: "spouse",
						is_disabled?: false,
						dob: spouse_dob,
            is_primary_member?: false
					)
				end
        let(:spouse_member_enrollment) do
          ::BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: spouse_member_id
          )
        end
				let(:spouse_age) { 22 }

        let(:roster_members) { [employee, spouse] }
        let(:member_enrollments) { [employee_enrollment, spouse_member_enrollment] }

				before(:each) do
					allow(contribution_model).to receive(:map_relationship_for).with("self", employee_age, false).and_return("employee")
					allow(contribution_model).to receive(:map_relationship_for).with("spouse", spouse_age, false).and_return("spouse")
          allow(family_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1}).and_return(true)
          allow(family_contribution_unit).to receive(:match?).with({"employee" => 1}).and_return(false)
          allow(employee_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1}).and_return(false)
          allow(employee_contribution_unit).to receive(:match?).with({"employee" => 1}).and_return(true)
				end

				it "removes the spouse" do
					optimized_roster_entry = subject.calculate_optimal_group_for(
						contribution_model,
						roster_entry,
						sponsor_contribution
					)
          dependent_ids = optimized_roster_entry.members.map(&:member_id)
          dependent_enrollment_ids = optimized_roster_entry.group_enrollment.member_enrollments.map(&:member_id)
          expect(dependent_ids).not_to include(spouse_member_id)
          expect(dependent_enrollment_ids).not_to include(spouse_member_id)
				end
			end
		end

		describe "given:
			- a sponsor which offers composite rating and contributions
			- with 'employee_only', 'employee_and_spouse', 'employee_and_other_dependents', and 'family' groups
			- where only 'family' is the only level NOT offered by the sponsor" do

			let(:contribution_model) do
        instance_double(
          ::BenefitMarkets::ContributionModels::ContributionModel,
          contribution_units: [
            employee_contribution_unit,
            employee_and_spouse_contribution_unit,
            employee_and_dependents_contribution_unit,
            family_contribution_unit
          ]
        )
      end

      let(:employee_contribution_unit) do
        instance_double(
          ::BenefitMarkets::ContributionModels::ContributionUnit,
          id: "employee_contribution_unit_id"
        )
      end

      let(:employee_and_spouse_contribution_unit) do
        instance_double(
          ::BenefitMarkets::ContributionModels::ContributionUnit,
          id: "employee_and_spouse_contribution_unit_id"
        )
      end

      let(:employee_and_dependents_contribution_unit) do
        instance_double(
          ::BenefitMarkets::ContributionModels::ContributionUnit,
          id: "employee_and_dependents_contribution_unit_id"
        )
      end

      let(:family_contribution_unit) do
        instance_double(
          ::BenefitMarkets::ContributionModels::ContributionUnit,
          id: "family_contribution_unit_id"
        )
      end

			let(:sponsor_contribution) do
				instance_double(
					::BenefitSponsors::SponsoredBenefits::SponsorContribution,
					id: "a sponsor_conribution_id",
					contribution_levels: [
            employee_contribution_level,
            employee_and_spouse_contribution_level,
            employee_and_dependents_contribution_level,
            family_contribution_level]
				)
			end

      let(:employee_contribution_level) do
				instance_double(
					::BenefitSponsors::SponsoredBenefits::ContributionLevel,
          contribution_unit_id: "employee_contribution_unit_id",
          is_offered: true
        )
      end

      let(:employee_and_spouse_contribution_level) do
				instance_double(
					::BenefitSponsors::SponsoredBenefits::ContributionLevel,
          contribution_unit_id: "employee_and_spouse_contribution_unit_id",
          is_offered: true
        )
      end

      let(:employee_and_dependents_contribution_level) do
				instance_double(
					::BenefitSponsors::SponsoredBenefits::ContributionLevel,
          contribution_unit_id: "employee_and_dependents_contribution_unit_id",
          is_offered: true
        )
      end

      let(:family_contribution_level) do
				instance_double(
					::BenefitSponsors::SponsoredBenefits::ContributionLevel,
          contribution_unit_id: "family_contribution_unit_id",
          is_offered: false
        )
      end

			describe "
				given:
					- a roster
					- with an employee
					- with a spouse
          - a child
			" do

				let(:spouse_member_id) { "some_spouse_id" }
				let(:spouse_dob) { Date.new(1995, 9, 27) }
				let(:spouse) do
					instance_double(
						"::BenefitMarkets::SponsoredBenefits::RosterMember",
						member_id: spouse_member_id,
						relationship: "spouse",
						is_disabled?: false,
						dob: spouse_dob,
            is_primary_member?: false
					)
				end
        let(:spouse_member_enrollment) do
          ::BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: spouse_member_id
          )
        end
				let(:spouse_age) { 22 }

				let(:child_member_id) { "some_child_member_id" }
				let(:child_dob) { Date.new(2015, 1, 1) }
				let(:child) do
					instance_double(
						"::BenefitMarkets::SponsoredBenefits::RosterMember",
						member_id: child_member_id,
						relationship: "child",
						is_disabled?: false,
						dob: child_dob,
            is_primary_member?: false
					)
				end
        let(:child_member_enrollment) do
          ::BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: child_member_id
          )
        end
        let(:child_age) { 3 }

				let(:roster_members) { [employee, spouse, child] }
				let(:member_enrollments) { [employee_enrollment, spouse_member_enrollment, child_member_enrollment] }

				before(:each) do
					allow(contribution_model).to receive(:map_relationship_for).with("self", employee_age, false).and_return("employee")
					allow(contribution_model).to receive(:map_relationship_for).with("spouse", spouse_age, false).and_return("spouse")
					allow(contribution_model).to receive(:map_relationship_for).with("child", child_age, false).and_return("dependent")
          allow(employee_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1, "dependent" => 1}).and_return(false)
          allow(employee_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1}).and_return(false)
          allow(employee_contribution_unit).to receive(:match?).with({"employee" => 1, "dependent" => 1}).and_return(false)
          allow(employee_contribution_unit).to receive(:match?).with({"employee" => 1}).and_return(true)
          allow(family_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1, "dependent" => 1}).and_return(true)
          allow(family_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1}).and_return(false)
          allow(family_contribution_unit).to receive(:match?).with({"employee" => 1, "dependent" => 1}).and_return(false)
          allow(family_contribution_unit).to receive(:match?).with({"employee" => 1}).and_return(false)
          allow(employee_and_spouse_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1, "dependent" => 1}).and_return(false)
          allow(employee_and_spouse_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1}).and_return(true)
          allow(employee_and_spouse_contribution_unit).to receive(:match?).with({"employee" => 1, "dependent" => 1}).and_return(false)
          allow(employee_and_spouse_contribution_unit).to receive(:match?).with({"employee" => 1}).and_return(false)
          allow(employee_and_dependents_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1, "dependent" => 1}).and_return(false)
          allow(employee_and_dependents_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1}).and_return(false)
          allow(employee_and_dependents_contribution_unit).to receive(:match?).with({"employee" => 1, "dependent" => 1}).and_return(true)
          allow(employee_and_dependents_contribution_unit).to receive(:match?).with({"employee" => 1}).and_return(false)
				end

				it "keeps the spouse" do
					optimized_roster_entry = subject.calculate_optimal_group_for(
						contribution_model,
						roster_entry,
						sponsor_contribution
					)
          dependent_ids = optimized_roster_entry.members.map(&:member_id)
          dependent_enrollment_ids = optimized_roster_entry.group_enrollment.member_enrollments.map(&:member_id)
          expect(dependent_ids).to include(spouse_member_id)
          expect(dependent_enrollment_ids).to include(spouse_member_id)
				end

				it "removes the child" do
					optimized_roster_entry = subject.calculate_optimal_group_for(
						contribution_model,
						roster_entry,
						sponsor_contribution
					)
          dependent_enrollment_ids = optimized_roster_entry.group_enrollment.member_enrollments.map(&:member_id)
          dependent_ids = optimized_roster_entry.members.map(&:member_id)
					expect(dependent_ids).not_to include(child_member_id)
					expect(dependent_enrollment_ids).not_to include(child_member_id)
				end
			end

			describe "
				given:
          - a roster
          - with an employee
          - with a spouse
          - with 2 children
        " do

				let(:spouse_member_id) { "some_spouse_id" }
				let(:spouse_dob) { Date.new(1995, 9, 27) }
				let(:spouse) do
					instance_double(
						"::BenefitMarkets::SponsoredBenefits::RosterMember",
						member_id: spouse_member_id,
						relationship: "spouse",
						is_disabled?: false,
						dob: spouse_dob,
            is_primary_member?: false
					)
				end
        let(:spouse_member_enrollment) do
          ::BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: spouse_member_id
          )
        end
				let(:spouse_age) { 22 }

				let(:child1_member_id) { "some_child1_member_id" }
				let(:child1_dob) { Date.new(2015, 1, 1) }
				let(:child1) do
					instance_double(
						"::BenefitMarkets::SponsoredBenefits::RosterMember",
						member_id: child1_member_id,
						relationship: "child",
						is_disabled?: false,
						dob: child1_dob,
            is_primary_member?: false
					)
				end
        let(:child1_member_enrollment) do
          ::BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: child1_member_id
          )
        end
        let(:child1_age) { 3 }

				let(:child2_member_id) { "some_child2_member_id" }
				let(:child2_dob) { Date.new(2015, 1, 1) }
				let(:child2) do
					instance_double(
						"::BenefitMarkets::SponsoredBenefits::RosterMember",
						member_id: child2_member_id,
						relationship: "child",
						is_disabled?: false,
						dob: child2_dob,
            is_primary_member?: false
					)
				end
        let(:child2_member_enrollment) do
          ::BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: child2_member_id
          )
        end
        let(:child2_age) { 3 }

        let(:roster_members) { [employee, spouse, child1, child2] }
        let(:member_enrollments) { [employee_enrollment, spouse_member_enrollment, child1_member_enrollment, child2_member_enrollment] }

				before(:each) do
					allow(contribution_model).to receive(:map_relationship_for).with("self", employee_age, false).and_return("employee")
					allow(contribution_model).to receive(:map_relationship_for).with("spouse", spouse_age, false).and_return("spouse")
					allow(contribution_model).to receive(:map_relationship_for).with("child", child1_age, false).and_return("dependent")
					allow(contribution_model).to receive(:map_relationship_for).with("child", child2_age, false).and_return("dependent")
          allow(employee_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1, "dependent" => 1}).and_return(false)
          allow(employee_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1, "dependent" => 2}).and_return(false)
          allow(employee_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1}).and_return(false)
          allow(employee_contribution_unit).to receive(:match?).with({"employee" => 1, "dependent" => 1}).and_return(false)
          allow(employee_contribution_unit).to receive(:match?).with({"employee" => 1, "dependent" => 2}).and_return(false)
          allow(employee_contribution_unit).to receive(:match?).with({"employee" => 1}).and_return(true)
          allow(family_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1, "dependent" => 1}).and_return(true)
          allow(family_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1, "dependent" => 2}).and_return(true)
          allow(family_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1}).and_return(false)
          allow(family_contribution_unit).to receive(:match?).with({"employee" => 1, "dependent" => 1}).and_return(false)
          allow(family_contribution_unit).to receive(:match?).with({"employee" => 1, "dependent" => 2}).and_return(false)
          allow(family_contribution_unit).to receive(:match?).with({"employee" => 1}).and_return(false)
          allow(employee_and_spouse_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1, "dependent" => 1}).and_return(false)
          allow(employee_and_spouse_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1, "dependent" => 2}).and_return(false)
          allow(employee_and_spouse_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1}).and_return(true)
          allow(employee_and_spouse_contribution_unit).to receive(:match?).with({"employee" => 1, "dependent" => 1}).and_return(false)
          allow(employee_and_spouse_contribution_unit).to receive(:match?).with({"employee" => 1, "dependent" => 2}).and_return(false)
          allow(employee_and_spouse_contribution_unit).to receive(:match?).with({"employee" => 1}).and_return(false)
          allow(employee_and_dependents_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1, "dependent" => 1}).and_return(false)
          allow(employee_and_dependents_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1, "dependent" => 2}).and_return(false)
          allow(employee_and_dependents_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1}).and_return(false)
          allow(employee_and_dependents_contribution_unit).to receive(:match?).with({"employee" => 1, "dependent" => 1}).and_return(true)
          allow(employee_and_dependents_contribution_unit).to receive(:match?).with({"employee" => 1, "dependent" => 2}).and_return(true)
          allow(employee_and_dependents_contribution_unit).to receive(:match?).with({"employee" => 1}).and_return(false)
				end

				it "keeps the children" do
					optimized_roster_entry = subject.calculate_optimal_group_for(
						contribution_model,
						roster_entry,
						sponsor_contribution
					)
          dependent_ids = optimized_roster_entry.members.map(&:member_id)
          dependent_enrollment_ids = optimized_roster_entry.group_enrollment.member_enrollments.map(&:member_id)
					expect(dependent_ids).to include(child1_member_id)
					expect(dependent_ids).to include(child2_member_id)
          expect(dependent_enrollment_ids).to include(child1_member_id)
          expect(dependent_enrollment_ids).to include(child2_member_id)
				end

				it "removes the spouse" do
					optimized_roster_entry = subject.calculate_optimal_group_for(
						contribution_model,
						roster_entry,
						sponsor_contribution
					)
          dependent_ids = optimized_roster_entry.members.map(&:member_id)
          dependent_enrollment_ids = optimized_roster_entry.group_enrollment.member_enrollments.map(&:member_id)
          expect(dependent_ids).not_to include(spouse_member_id)
          expect(dependent_enrollment_ids).not_to include(spouse_member_id)
				end
			end
		end
	end
end
