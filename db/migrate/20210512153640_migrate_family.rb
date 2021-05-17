# frozen_string_literal: true

# require 'aca_entities/operations/families/process_mcr_application'

class MigrateFamily < Mongoid::Migration
  def self.up
    # input = file
    ::AcaEntities::Ffe::Transformers::McrTo::Family.call(input, { transform_mode: worker_mode }) do |payload|
      # Below line is for testing
      # family_hash = JSON.parse(File.read(Pathname.pwd.join("spec/test_data/family_transform_result.json")))

      family_hash = Operations::Ffe::TransformApplication.new.call(payload)
      build_family(family_hash) # for testting, remove this
      build_iap(family_hash['magi_medicaid_applications'].first.merge!("family_id": @family.id, benchmark_product_id: BSON::ObjectId.new, years_to_renew: 5))
    end
  end

  def self.build_iap(iap_hash)
    sanitize_iap_hash = sanitize_applicant_params(iap_hash)
    result = ::FinancialAssistance::Operations::Application::Create.new.call(params: sanitize_iap_hash)

    result.success? ? result.success : result.failure
  end

  def self.build_family(family_hash)
    @family = Family.new(family_hash.except('hbx_id', 'foreign_keys', 'broker_accounts', 'magi_medicaid_applications', 'family_members', 'households'))

    family_hash['family_members'].each do |family_member_hash|
      create_member(family_member_hash)
    end

    @family.save!
  end

  def self.create_member(family_member_hash)
    this
    person_params = sanitize_person_params(family_member_hash)
    person_result = create_or_update_person(person_params)

    if person_result.success?
      @person = person_result.success
      @family_member = create_or_update_family_member(@person, @family, family_member_hash)
      consumer_role_params = family_member_hash['person']['consumer_role']
      create_or_update_consumer_role(consumer_role_params.merge(is_consumer_role: true), @family_member)
      # create_or_update_vlp_document(applicant_params, @person)
    else
      @person
    end
  end

  def self.create_or_update_person(person_params)
    Operations::People::CreateOrUpdate.new.call(params: person_params)
  end

  def self.create_or_update_consumer_role(applicant_params, family_member)
    return unless applicant_params[:is_consumer_role]

    # assign_citizen_status
    Operations::People::CreateOrUpdateConsumerRole.new.call(params: { applicant_params: applicant_params, family_member: family_member })
  end

  def self.create_or_update_family_member(person, family, family_member_hash)
    family_member = family.family_members.detect { |fm| fm.person_id.to_s == person.id.to_s }
    if family_member && (family_member_hash.key?(:is_active) ? family_member.is_active == family_member_hash[:is_active] : true)
      return family_member
    end

    fm_attr = { "is_primary_applicant": family_member_hash['is_primary_applicant'],
                "is_consent_applicant": family_member_hash['is_consent_applicant'],
                "is_coverage_applicant": family_member_hash['is_coverage_applicant'],
                "is_active": family_member_hash['is_active'] }

    family_member = family.add_family_member(person, fm_attr)
    family_member.save!

    create_or_update_relationship(person, family, family_member_hash['person']['person_relationships'])
    family.save!
    family_member
  end

  def self.create_or_update_vlp_document(applicant_params, person)
    Operations::People::CreateOrUpdateVlpDocument.new.call(params: { applicant_params: applicant_params, person: person })
  end

  def self.create_or_update_relationship(person, family, relationship_kind)
    primary_person = family.primary_person
    exiting_relationship = primary_person.person_relationships.detect { |rel| rel.relative_id.to_s == person.id.to_s }
    if exiting_relationship && exiting_relationship.kind == relationship_kind
      return
    end

    primary_person.ensure_relationship_with(person, relationship_kind)
  end

  def self.sanitize_applicant_params(iap_hash)
    applicants_hash = iap_hash['applicants']
    sanitize_params = []
    applicants_hash.each do |applicant_hash|
      sanitize_params << {
        "family_member_id": BSON::ObjectId.new,
        "first_name": applicant_hash['name']['first_name'],
        "middle_name": applicant_hash['name']['middle_name'],
        "last_name": applicant_hash['name']['last_name'],
        "full_name": applicant_hash['name']['full_name'],
        "name_sfx": applicant_hash['name']['name_sfx'],
        "name_pfx": applicant_hash['name']['name_pfx'],
        "alternate_name": applicant_hash['name']['alternate_name'],
        "ssn": '123456789',
        # "encrypted_ssn": applicant_hash['identifying_information']['encrypted_ssn'],
        "has_ssn": applicant_hash['identifying_information']['has_ssn'],
        "gender": applicant_hash['demographic']['gender'],
        "dob": applicant_hash['demographic']['dob'],
        "ethnicity": applicant_hash['demographic']['ethnicity'],
        "race": applicant_hash['demographic']['race'],
        "is_veteran_or_active_military": applicant_hash['demographic']['is_veteran_or_active_military'],
        "is_vets_spouse_or_child": applicant_hash['demographic']['is_vets_spouse_or_child'],

        "is_incarcerated": applicant_hash['attestation']['is_incarcerated'],
        "is_self_attested_disabled": applicant_hash['attestation']['is_self_attested_disabled'],
        "is_self_attested_blind": applicant_hash['attestation']['is_self_attested_blind'],
        "is_self_attested_long_term_care": applicant_hash['attestation']['is_self_attested_long_term_care'],

        "is_primary_applicant": applicant_hash['is_primary_applicant'],
        "native_american_information": applicant_hash['native_american_information'],

        "citizen_status": applicant_hash['citizenship_immigration_status_information']['citizen_status'],
        "is_resident_post_092296": applicant_hash['citizenship_immigration_status_information']['is_resident_post_092296'],
        "is_lawful_presence_self_attested": applicant_hash['citizenship_immigration_status_information']['is_lawful_presence_self_attested'],

        "is_consumer_role": true, # applicant_hash['is_consumer_role'],
        "is_resident_role": applicant_hash['is_resident_role'],
        "is_applying_coverage": applicant_hash['is_applying_coverage'],
        "is_consent_applicant": applicant_hash['is_consent_applicant'],
        "vlp_document": applicant_hash['vlp_document'],

        "person_hbx_id": applicant_hash['person_hbx_id'],
        "is_required_to_file_taxes": applicant_hash['is_required_to_file_taxes'],
        "tax_filer_kind": applicant_hash['tax_filer_kind'],
        "is_joint_tax_filing": applicant_hash['is_joint_tax_filing'],
        "is_claimed_as_tax_dependent": applicant_hash['is_claimed_as_tax_dependent'],
        "claimed_as_tax_dependent_by": applicant_hash['claimed_as_tax_dependent_by'],

        "is_student": applicant_hash['student']['is_student'],
        "student_kind": applicant_hash['student']['student_kind'],
        "student_school_kind": applicant_hash['student']['student_school_kind'],
        "student_status_end_on": applicant_hash['student']['student_status_end_on'],

        "is_refugee": applicant_hash['is_refugee'],
        "is_trafficking_victim": applicant_hash['is_trafficking_victim'],

        "is_former_foster_care": applicant_hash['foster_care']['is_former_foster_care'],
        "age_left_foster_care": applicant_hash['foster_care']['age_left_foster_care'],
        "foster_care_us_state": applicant_hash['foster_care']['foster_care_us_state'],
        "had_medicaid_during_foster_care": applicant_hash['foster_care']['had_medicaid_during_foster_care'],

        "is_pregnant": applicant_hash['pregnancy_information']['is_pregnant'],
        "is_enrolled_on_medicaid": applicant_hash['pregnancy_information']['is_enrolled_on_medicaid'],
        "is_post_partum_period": applicant_hash['pregnancy_information']['is_post_partum_period'],
        "expected_children_count": applicant_hash['pregnancy_information']['expected_children_count'],
        "pregnancy_due_on": applicant_hash['pregnancy_information']['pregnancy_due_on'],
        "pregnancy_end_on": applicant_hash['pregnancy_information']['pregnancy_end_on'],

        "is_subject_to_five_year_bar": applicant_hash['is_refugee'],
        "is_five_year_bar_met": applicant_hash['is_refugee'],
        "is_forty_quarters": applicant_hash['is_forty_quarters'],
        "is_ssn_applied": applicant_hash['is_ssn_applied'],
        "non_ssn_apply_reason": applicant_hash['non_ssn_apply_reason'],
        "moved_on_or_after_welfare_reformed_law": applicant_hash['moved_on_or_after_welfare_reformed_law'],
        "is_currently_enrolled_in_health_plan": applicant_hash['is_currently_enrolled_in_health_plan'],
        "has_daily_living_help": applicant_hash['has_daily_living_help'],
        "need_help_paying_bills": applicant_hash['need_help_paying_bills'],
        "has_job_income": applicant_hash['has_job_income'],
        "has_self_employment_income": applicant_hash['has_self_employment_income'],
        "has_unemployment_income": applicant_hash['has_unemployment_income'],
        "has_other_income": applicant_hash['has_other_income'],
        "has_deductions": applicant_hash['has_deductions'],
        "has_enrolled_health_coverage": applicant_hash['has_enrolled_health_coverage'],
        "has_eligible_health_coverage": applicant_hash['has_eligible_health_coverage'],

        "addresses": applicant_hash['addresses'],
        "emails": applicant_hash['emails'],
        "phones": applicant_hash['phones'],
        "incomes": applicant_hash['incomes'],
        "benefits": applicant_hash['benefits'],
        "deductions": applicant_hash['deductions'],

        "is_medicare_eligible": applicant_hash['is_medicare_eligible'],
        "has_insurance": applicant_hash['has_insurance'],
        "has_state_health_benefit": applicant_hash['has_state_health_benefit'],
        "had_prior_insurance": applicant_hash['had_prior_insurance'],
        "age_of_applicant": applicant_hash['age_of_applicant'],
        "is_self_attested_long_term_care": applicant_hash['is_self_attested_long_term_care'],
        "hours_worked_per_week": applicant_hash['hours_worked_per_week'],
        "indian_tribe_member": true
      }
    end
    iap_hash.except!('applicants').merge!("applicants": sanitize_params)
  end

  def self.sanitize_person_params(family_member_hash)
    person_hash = family_member_hash['person']
    {
      "first_name": person_hash['person_name']['first_name'],
      "last_name": person_hash['person_name']['last_name'],
      "full_name": person_hash['person_name']['full_name'],
      "ssn": person_hash['person_demographics']['ssn'],
      "no_ssn": person_hash['person_demographics']['no_ssn'],
      "gender": person_hash['person_demographics']['gender'],
      "dob": person_hash['person_demographics']['dob'],
      "date_of_death": person_hash['person_demographics']['date_of_death'],
      "dob_check": person_hash['person_demographics']['dob_check'],
      "is_incarcerated": person_hash['person_demographics']['is_incarcerated'],
      "tribal_id": person_hash['person_demographics']['tribal_id'],
      "language_code": person_hash['person_demographics']['language_code'],
      "is_tobacco_user": person_hash['person_health']['is_tobacco_user'],
      "is_physically_disabled": person_hash['person_health']['is_physically_disabled'],
      "is_homeless": person_hash['is_homeless'],
      "is_temporarily_out_of_state": person_hash['is_temporarily_out_of_state'],
      "age_off_excluded": person_hash['age_off_excluded'],
      "is_active": person_hash['is_active'],
      "is_disabled": person_hash['is_disabled'],
      "individual_market_transitions": person_hash['individual_market_transitions'],
      "verification_types": person_hash['verification_types'],
      "addresses": person_hash['addresses'],
      "emails": person_hash['emails'],
      "phones": person_hash['phones']
    }
  end

  def self.down; end
end
