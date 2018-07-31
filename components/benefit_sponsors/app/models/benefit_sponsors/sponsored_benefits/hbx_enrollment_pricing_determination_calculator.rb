module BenefitSponsors
	module SponsoredBenefits
		class HbxEnrollmentPricingDeterminationCalculator
			EnrollmentProductAdapter = Struct.new(:id, :issuer_profile_id, :active_year)

			EnrollmentMemberAdapter = Struct.new(:member_id, :dob, :relationship, :is_primary_member, :is_disabled) do
				def is_disabled?
					is_disabled
				end

				def is_primary_member?
					is_primary_member
				end
			end

			class HbxEnrollmentRosterMapper
				include Enumerable

				def initialize(he_id_list, s_benefit)
					@hbx_enrollment_id_list = he_id_list
					@sponsored_benefit = s_benefit
          @issuer_profile_id_map = {}
          @active_year_map = {}
          ::BenefitMarkets::Products::Product.pluck(:_id, :issuer_profile_id, :"application_period").each do |rec|
            @issuer_profile_id_map[rec.first] = rec[1]
            @active_year_map[rec.first] = rec.last["min"].year
          end
				end

				def each
					@hbx_enrollment_id_list.each_slice(200) do |heidl|
						search_criteria(heidl).each do |agg_result|
							yield rosterize_hbx_enrollment(agg_result)
						end
					end
				end

				def search_criteria(enrollment_ids)
					Family.collection.aggregate([
						{"$match" => {
							"households.hbx_enrollments" => { "$elemMatch" => {
								"hbx_id" => {"$in" => enrollment_ids}
							}}}},
							{"$project" => {"households" => {"hbx_enrollments": 1}, "family_members" => {"_id": 1, "person_id": 1}}},
							{"$unwind" => "$households"},
							{"$unwind" => "$households.hbx_enrollments"},
							{"$match" => {
								"households.hbx_enrollments.hbx_id" => {"$in" => enrollment_ids}
							}},
							{"$project" => {
								"hbx_enrollment" => {
									"effective_on" => "$households.hbx_enrollments.effective_on",
									"hbx_enrollment_members" => "$households.hbx_enrollments.hbx_enrollment_members",
									"_id" => "$households.hbx_enrollments.hbx_id",
									"product_id" => "$households.hbx_enrollments.product_id"
								},
								"family_members" => 1,
								"people_ids" => {
									"$map" => {
										"input" => "$family_members",
										"as" => "fm",
										"in" => "$$fm.person_id"
									}
								}
							}},
							{"$lookup" => {
								"from" => "people",
								"localField" => "people_ids",
								"foreignField" => "_id",
								"as" => "people"
							}},
							{"$project" => {
								"hbx_enrollment" => 1,
                "product" => 1,
								"family_members" => 1,
								"people" => {"_id" => 1, "dob" => 1, "person_relationships" => 1, "is_disabled" => 1}
							}}
					])
				end

				def rosterize_hbx_enrollment(enrollment_record)
					person_id_map = {}
					enrollment_record["people"].each do |pers|
						person_id_map[pers["_id"]] = pers
					end
					subject_arr, dep_members = enrollment_record["hbx_enrollment"]["hbx_enrollment_members"].partition do |entry|
						entry["is_subscriber"]
					end
					sub_member = subject_arr.first
					sub_person = nil
					family_people_ids = {}
					family_dobs = {}
					family_disables = {}
					enrollment_record["family_members"].each do |fm|
						family_people_ids[fm["_id"]] = fm["person_id"]
						family_dobs[fm["_id"]] = person_id_map[fm["person_id"]]["dob"]
						family_disables[fm["_id"]] = person_id_map[fm["person_id"]]["is_disabled"]
						if fm["_id"] == sub_member["applicant_id"]
							sub_person = person_id_map[fm["person_id"]]
						end
					end
					rel_map = {}
					member_entries = []
					member_enrollments = []
					if sub_person["person_relationships"]
						sub_person["person_relationships"].each do |pr|
							rel_map[pr["relative_id"]] = pr["kind"]
						end
					end
					member_entries << EnrollmentMemberAdapter.new(
						sub_member["_id"],
						sub_person["dob"],
						"self",
						true,
						sub_person["is_disabled"]
					)
					member_enrollments << ::BenefitSponsors::Enrollments::MemberEnrollment.new({
						member_id: sub_member["_id"],
						coverage_eligibility_on: sub_member["effective_on"]
					})
					dep_members.each do |dep_member|
						person_id = family_people_ids[dep_member["applicant_id"]]
						member_entries << EnrollmentMemberAdapter.new(
							dep_member["_id"],
							family_dobs[dep_member["applicant_id"]],
							rel_map[person_id],
							false,
							family_disables[dep_member["applicant_id"]],
						)
						member_enrollments << ::BenefitSponsors::Enrollments::MemberEnrollment.new({
							member_id: dep_member["_id"],
							coverage_eligibility_on: dep_member["effective_on"]
						})
					end
          product = EnrollmentProductAdapter.new(
            enrollment_record["hbx_enrollment"]["product_id"],
            @issuer_profile_id_map[enrollment_record["hbx_enrollment"]["product_id"]],
            @active_year_map[enrollment_record["hbx_enrollment"]["product_id"]]
          )
					group_enrollment = ::BenefitSponsors::Enrollments::GroupEnrollment.new(
						{
							product: product,
							previous_product: product,
							rate_schedule_date: @sponsored_benefit.rate_schedule_date,
							coverage_start_on: enrollment_record["hbx_enrollment"]["effective_on"],
							member_enrollments: member_enrollments,
							rating_area: @sponsored_benefit.recorded_rating_area.exchange_provided_code
						})
					::BenefitSponsors::Members::MemberGroup.new(
						member_entries,
						{group_enrollment: group_enrollment}
					)
				end
			end

			attr_reader :benefit_sponsorship, :as_of_date

			def initialize(b_sponsorship, as_date)
				@benefit_sponsorship = b_sponsorship
				@as_of_date = as_date
			end

			def calculate(sponsored_benefit, hbx_enrollment_id_list, enrollment_count, waiver_count)
				p_package = sponsored_benefit.product_package
				pricing_model = p_package.pricing_model
				contribution_model = p_package.contribution_model
				p_calculator = pricing_model.pricing_calculator
				c_calculator = contribution_model.contribution_calculator
				p_determination_builder = p_calculator.pricing_determination_builder
				sponsor_contribution = construct_sponsor_contribution_if_needed(sponsored_benefit, p_package)
				price = 0.00
				contribution = 0.00
				if enrollment_count < 1
					return sponsor_contribution
				end
				if p_determination_builder
					precalculate_costs(
						sponsored_benefit,
						pricing_model,
						contribution_model,
						sponsored_benefit.reference_product,
						sponsor_contribution,
						p_calculator,
						c_calculator,
						p_determination_builder,
            hbx_enrollment_id_list,
            enrollment_count,
            waiver_count
					)
				end
				sponsor_contribution
			end

			protected

			def construct_sponsor_contribution_if_needed(sponsored_benefit, product_package)
				return sponsored_benefit.sponsor_contribution if sponsored_benefit.sponsor_contribution.present?
				cm_builder = BenefitSponsors::SponsoredBenefits::ProductPackageToSponsorContributionService.new
				sponsor_contribution = cm_builder.build_sponsor_contribution(p_package)
				sponsor_contribution.sponsored_benefit = sponsored_benefit
				sponsor_contribution
			end

			def precalculate_costs(
				sponsored_benefit,
				pricing_model,
				contribution_model,
				reference_product,
				sponsor_contribution,
				p_calculator,
				c_calculator,
				p_determination_builder_klass,
				hbx_enrollment_id_list,
        enrollment_count,
        waiver_count
			)
				p_determination_builder = p_determination_builder_klass.new
				group_size = enrollment_count
				participation = calculate_participation_percent(group_size, waiver_count)
				sic_code = sponsor_contribution.sic_code
				group_mapper = HbxEnrollmentRosterMapper.new(hbx_enrollment_id_list, sponsored_benefit)
				p_determination_builder.create_pricing_determinations(sponsored_benefit, reference_product, pricing_model, group_mapper, group_size, participation, sic_code)
			end

			def eligible_employee_criteria
				::CensusEmployee.where(
					:benefit_sponsorship_id => benefit_sponsorship.id,
					:hired_on => {"$lte" => as_of_date},
					"$or" => [
						{ "terminated_on" => nil },
						{ "terminated_on" => { "$gt" => as_of_date} },
            { "terminated_on" => { "$lte" => as_of_date }, "aasm_state" => { "$in" => ["cobra_eligible", "cobra_linked", "cobra_termination_pending"] } }
					]
				)
			end

			def eligible_employee_count
				@eligible_employee_count ||= begin
                                       employee_count = eligible_employee_criteria.count
                                       (employee_count < 1) ? 1 : employee_count
                                     end
			end

			def calculate_participation_percent(group_size, waiver_count)
				enrolling_count = group_size + waiver_count
				return 1 if enrolling_count < 1
				(enrolling_count.to_f / eligible_employee_count) * 100.0
			end
		end
	end
end
