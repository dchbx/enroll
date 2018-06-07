module FinancialAssistanceWorld
  def consumer(*traits)
    attributes = traits.extract_options!
    @consumer ||= FactoryGirl.create :user, :consumer, *traits, :with_consumer_role, attributes
  end

  def application(*traits)
    attributes = traits.extract_options!
    attributes.merge!(family_id: consumer.primary_family.id)
    @application ||= FactoryGirl.create(:financial_assistance_application, *traits, attributes).tap do |application|
      application.populate_applicants_for(consumer.primary_family)
    end
  end

  def user_sign_up
    @user_sign_up_info ||= FactoryGirl.attributes_for :user
  end

  def personal_information
    address = FactoryGirl.attributes_for :address
    @personal_information ||= FactoryGirl.attributes_for :person, :with_consumer_role, :with_ssn, address
  end

  def create_plan
    hbx_profile = FactoryGirl.create(:hbx_profile)
    benefit_package = hbx_profile.benefit_sponsorship.benefit_coverage_periods.first.benefit_packages.first
  end
  
  def assign_benchmark_plan_id(application)
    hbx_profile = HbxProfile.all.first
    plan = Plan.all.first
    coverage_period = hbx_profile.benefit_sponsorship.current_benefit_coverage_period
    coverage_period.update_attributes!(slcsp_id: plan.id, slcsp: plan.id)
    application.update_attributes!(benchmark_plan_id: coverage_period.slcsp)    
  end

  def create_dummy_tax_households(application)
    coverage_year = TimeKeeper.date_of_record.year
    application.submit!
    application.tax_households.each do |txh|
      txh.update_attributes!(allocated_aptc: 200.00, is_eligibility_determined: true, effective_starting_on: Date.new(coverage_year, 01, 01))
      txh.eligibility_determinations.build(max_aptc: 200.00,
                                           csr_percent_as_integer: 0,
                                           csr_eligibility_kind: "csr_73",
                                           determined_on: TimeKeeper.datetime_of_record - 30.days,
                                           determined_at: TimeKeeper.datetime_of_record - 30.days,
                                           premium_credit_strategy_kind: "allocated_lump_sum_credit",
                                           e_pdc_id: "3110344",
                                           source: "Haven").save!
      txh.applicants.first.update_attributes!(is_medicaid_chip_eligible: false, is_ia_eligible: true, is_without_assistance: false)
    end
    application.update_attributes!(aasm_state: 'determined')
  end
end
World(FinancialAssistanceWorld)
