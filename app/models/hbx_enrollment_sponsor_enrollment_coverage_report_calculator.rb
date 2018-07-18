class HbxEnrollmentSponsorEnrollmentCoverageReportCalculator
	EnrollmentProductAdapter = Struct.new(:id, :issuer_profile_id, :active_year)
  
  MemberInfoAdapter = Struct.new(:prefix, :first_name, :middle_name, :last_name, :suffix, :encrypted_ssn) do
    def ssn
      return nil if encrypted_ssn.blank?
      Person.decrypt_ssn(encrypted_ssn)
    end
  end

	EnrollmentMemberAdapter = Struct.new(:member_id, :dob, :relationship, :is_primary_member, :is_disabled, :employee_role, :member_info, :sponsored_benefit) do
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
						"_id" => {"$in" => enrollment_ids}
					}}}},
					{"$project" => {"households" => {"hbx_enrollments": 1}, "family_members" => {"_id": 1, "person_id": 1}}},
					{"$unwind" => "$households"},
					{"$unwind" => "$households.hbx_enrollments"},
					{"$match" => {
						"households.hbx_enrollments._id" => {"$in" => enrollment_ids}
					}},
					{"$project" => {
						"hbx_enrollment" => {
							"effective_on" => "$households.hbx_enrollments.effective_on",
							"hbx_enrollment_members" => "$households.hbx_enrollments.hbx_enrollment_members",
							"_id" => "$households.hbx_enrollments._id",
              "product_id" => "$households.hbx_enrollments.product_id",
              "employee_role_id" => "$households.hbx_enrollments.employee_role_id",
              "kind" => "$households.hbx_enrollments.kind"
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
						"family_members" => 1,
						"people" => ({"_id" => 1, "dob" => 1, "person_relationships" => 1, "is_disabled" => 1, "employee_roles" => 1}.merge(person_info_fields))
					}}
			])
		end

    def person_info_fields
      {
        "first_name" => 1,
        "last_name" => 1,
        "middle_name" => 1,
        "name_pfx" => 1,
        "name_sfx" => 1,
        "encrypted_ssn" => 1
      }
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
		  family_names = {}
			enrollment_record["family_members"].each do |fm|
				family_people_ids[fm["_id"]] = fm["person_id"]
				family_dobs[fm["_id"]] = person_id_map[fm["person_id"]]["dob"]
				family_disables[fm["_id"]] = person_id_map[fm["person_id"]]["is_disabled"]
        family_names[fm["_id"]] = MemberInfoAdapter.new(
          person_id_map[fm["person_id"]]["name_pfx"],
          person_id_map[fm["person_id"]]["first_name"],
          person_id_map[fm["person_id"]]["middle_name"],
          person_id_map[fm["person_id"]]["last_name"],
          person_id_map[fm["person_id"]]["name_sfx"],
          person_id_map[fm["person_id"]]["encrypted_ssn"]
        )
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
      employee_roles = (sub_person["employee_roles"].map { |r| Mongoid::Factory.build(::EmployeeRole, r) })
      employee_role = employee_roles.detect do |er|
        er.id == enrollment_record["hbx_enrollment"]["employee_role_id"]
      end
      member_entries << EnrollmentMemberAdapter.new(
        sub_member["_id"],
        sub_person["dob"],
        "self",
        true,
        sub_person["is_disabled"],
        employee_role,
        MemberInfoAdapter.new(
          sub_person["name_pfx"],
          sub_person["first_name"],
          sub_person["middle_name"],
          sub_person["last_name"],
          sub_person["name_sfx"],
          sub_person["encrypted_ssn"]
        ),
        @sponsored_benefit
      )
      member_enrollments << ::BenefitSponsors::Enrollments::MemberEnrollment.new({
        member_id: sub_member["_id"],
        coverage_eligibility_on: sub_member["coverage_start_on"]
      })
      dep_members.each do |dep_member|
        person_id = family_people_ids[dep_member["applicant_id"]]
        member_entries << EnrollmentMemberAdapter.new(
          dep_member["_id"],
          family_dobs[dep_member["applicant_id"]],
          rel_map[person_id],
          false,
          family_disables[dep_member["applicant_id"]],
          nil,
          family_names[dep_member["applicant_id"]],
          nil
        )
        member_enrollments << ::BenefitSponsors::Enrollments::MemberEnrollment.new({
          member_id: dep_member["_id"],
          coverage_eligibility_on: dep_member["coverage_start_on"]
        })
      end
      product = EnrollmentProductAdapter.new(
            enrollment_record["hbx_enrollment"]["product_id"],
            @issuer_profile_id_map[enrollment_record["hbx_enrollment"]["product_id"]],
            @active_year_map[enrollment_record["hbx_enrollment"]["product_id"]]
          )
      contribution_prohibited = (enrollment_record["hbx_enrollment"]["kind"].to_s == "employer_sponsored_cobra")
      group_enrollment = ::BenefitSponsors::Enrollments::GroupEnrollment.new(
        {
          product: product,
          previous_product: product,
          rate_schedule_date: @sponsored_benefit.rate_schedule_date,
          coverage_start_on: enrollment_record["hbx_enrollment"]["effective_on"],
          member_enrollments: member_enrollments, 
          rating_area: @sponsored_benefit.recorded_rating_area.exchange_provided_code,
          sponsor_contribution_prohibited: contribution_prohibited
        })
      ::BenefitSponsors::Members::MemberGroup.new(
        member_entries,
        {group_enrollment: group_enrollment}
      )
    end
  end

  attr_reader :sponsored_benefit, :hbx_enrollment_id_list

  include Enumerable

  def initialize(s_benefit, hbx_enrollment_ids)
    @sponsored_benefit = s_benefit
    @hbx_enrollment_id_list = hbx_enrollment_ids
  end

  def each
    sponsor_contribution = sponsored_benefit.sponsor_contribution
    p_package = sponsored_benefit.product_package
    pricing_model = p_package.pricing_model
    contribution_model = p_package.contribution_model
    p_calculator = pricing_model.pricing_calculator
    c_calculator = contribution_model.contribution_calculator
    if hbx_enrollment_id_list.count < 1
      return
    end
    group_mapper = HbxEnrollmentRosterMapper.new(hbx_enrollment_id_list, sponsored_benefit)
    group_mapper.each do |ce_roster|
      price_group = p_calculator.calculate_price_for(pricing_model, ce_roster, sponsor_contribution)
      contribution_group = c_calculator.calculate_contribution_for(contribution_model, price_group, sponsor_contribution)
      yield contribution_group
    end
  end
end
