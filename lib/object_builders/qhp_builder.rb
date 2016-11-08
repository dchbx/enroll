class QhpBuilder
  LOG_PATH = "#{Rails.root}/log/rake_xml_import_plans_#{Time.now.to_s.gsub(' ', '')}.log"
  LOGGER = Logger.new(LOG_PATH)
  INVALID_PLAN_IDS = ["43849DC0060001", "92479DC0020003"] # These plan ids are suppressed and we dont save these while importing.
  BEST_LIFE_HIOS_IDS = ["95051DC0020003", "95051DC0020006", "95051DC0020004", "95051DC0020005"]

  def initialize(qhp_hash)
    @qhp_hash = qhp_hash
    @qhp_array = []
    if qhp_hash[:packages_list].present?
      if qhp_hash[:packages_list][:packages].present?
        @qhp_array = qhp_hash[:packages_list][:packages]
      end
    end
  end

  def add(qhp_hash, file_path)
    temp = qhp_hash[:packages_list][:packages]
    qhp_hash[:packages_list][:packages].each do |package|
      package[:plans_list].deep_merge!(carrier_name: search_carrier_name(file_path))
    end
    @qhp_array = @qhp_array + temp
  end

  def search_carrier_name(file_path)
    file_path = file_path.downcase
    carrier = if file_path.include?("aetna")
      "Aetna"
    elsif file_path.include?("dentegra")
      "Dentegra"
    elsif file_path.include?("delta")
      "Delta Dental"
    elsif file_path.include?("dominion")
      "Dominion"
    elsif file_path.include?("guardian")
      "Guardian"
    elsif file_path.include?("best life")
      "BestLife"
    elsif file_path.include?("metlife")
      "MetLife"
    elsif file_path.include?("united")
      "United Health Care"
    elsif file_path.include?("kaiser")
      "Kaiser"
    elsif file_path.include?("carefirst") || file_path.include?("cf")
      "CareFirst"
    end
  end

  def run
    @xml_plan_counter, @success_plan_counter = 0,0
    iterate_plans
    show_qhp_stats
    mark_2015_dental_plans_as_individual
    mark_2015_catastrophic_plans_as_individual
    mark_one_2015_plan_as_shop
    remove_2016_metlife_plans
  end

  def remove_2016_metlife_plans
    # deleting metlife plans based on carrier profile id
    Plan.where(active_year: 2016, carrier_profile_id: "53e67210eb899a460300001d").size
  end

  def mark_one_2015_plan_as_shop
    Plan.where(active_year: 2015, hios_id: /94506DC0350012/).each do |plan|
      plan.update_attribute(:market, "shop")
    end
  end

  def mark_2015_catastrophic_plans_as_individual
    Plan.catastrophic_level.by_active_year(2015).each do |plan|
      plan.update_attribute(:market, "individual")
    end
  end

  def mark_2015_dental_plans_as_individual
    # find ivl dental plans that are marked as shop.
    #delete bestone plans as they do not have corresponding serff templates.
    Plan.shop_dental_by_active_year(2015).each do |plan|
      if BEST_LIFE_HIOS_IDS.include?(plan.hios_id)
        plan.destroy
      else
        plan.update_attribute(:market, "individual") if plan.coverage_kind == "dental"
      end
    end
  end

  def update_dental_plans
    Plan.where(:active_year.in => [2015, 2016], coverage_kind: "dental").each do |plan|
      plan.hios_id = plan.hios_base_id
      plan.csr_variant_id = ""
      plan.save
    end
  end

  def iterate_plans
    update_dental_plans
    # @qhp_hash[:packages_list][:packages].each do |plans|
    @qhp_array.each do |plans|
      @plans = plans
      @xml_plan_counter += plans[:plans_list][:plans].size
      plans[:plans_list][:plans].each do |plan|
        @plan = plan
        @carrier_name = plans[:plans_list][:carrier_name]
        build_qhp_params
      end
    end
  end

  def build_qhp_params
    build_qhp
    build_benefits
    build_cost_share_variances_list
    validate_and_persist_qhp
  end

  def show_qhp_stats
    puts "*"*80
    puts "Total Number of Plans imported from xml: #{@xml_plan_counter}."
    puts "Total Number of Plans Saved to database: #{@success_plan_counter}."
    puts "Check the log file #{LOG_PATH}"
    puts "*"*80
    LOGGER.info "\nTotal Number of Plans imported from xml: #{@xml_plan_counter}.\n"
    LOGGER.info "\nTotal Number of Plans Saved to database: #{@success_plan_counter}.\n"
  end

  def validate_and_persist_qhp
    begin
      associate_plan_with_qhp
      @qhp.save!
      @success_plan_counter += 1
      LOGGER.info "\nSaved Plan: #{@qhp.plan_marketing_name}, hios product id: #{@qhp.hios_product_id} \n"
    rescue Exception => e
      LOGGER.error "\n Failed to create plan: #{@qhp.plan_marketing_name}, \n hios product id: #{@qhp.hios_product_id} \n Exception Message: #{e.message} \n\n Errors: #{@qhp.errors.full_messages} \n ******************** \n"
    end
  end

  def associate_plan_with_qhp
    @dental_metal_level = ""
    effective_date = @qhp.plan_effective_date.to_date
    @qhp.plan_effective_date = effective_date.beginning_of_year
    @qhp.plan_expiration_date = effective_date.end_of_year
    @plan_year = effective_date.year
    if @plan_year > 2015 && !INVALID_PLAN_IDS.include?(@qhp.standard_component_id.strip)
      @dental_metal_level = @qhp.metal_level.downcase if @qhp.dental_plan_only_ind.downcase == "yes"
      create_plan_from_serff_data
    end
    candidate_plans = Plan.where(active_year: @plan_year, hios_id: /#{@qhp.standard_component_id.strip}/).to_a
    plan = candidate_plans.sort_by do |plan| plan.hios_id.gsub('-','').to_i end.first
    plans_to_update = Plan.where(active_year: @plan_year, hios_id: /#{@qhp.standard_component_id.strip}/).to_a
    plans_to_update.each do |up_plan|
      nation_wide, dc_in_network = parse_nation_wide_and_dc_in_network
      up_plan.update_attributes(
          name: @qhp.plan_marketing_name.squish!,
          hios_id: up_plan.coverage_kind == "dental" ? up_plan.hios_id.split("-").first : up_plan.hios_id,
          hios_base_id: up_plan.hios_id.split("-").first,
          # csr_variant_id: up_plan.hios_id.include?("-") ? up_plan.hios_id.split("-").last : "",
          csr_variant_id: up_plan.coverage_kind == "dental" ? "" : up_plan.hios_id.split("-").last,
          plan_type: @qhp.plan_type.downcase,
          deductible: @qhp.qhp_cost_share_variances.first.qhp_deductable.in_network_tier_1_individual,
          family_deductible: @qhp.qhp_cost_share_variances.first.qhp_deductable.in_network_tier_1_family,
          nationwide: nation_wide,
          dc_in_network: dc_in_network,
          dental_level: @dental_metal_level
      )
      up_plan.save!
    end
    if plan.present?
      @qhp.plan = plan
    else
      puts "Plan Not Saved! Year: #{@qhp.active_year} :: Hios: #{@qhp.standard_component_id}, Plan Name: #{@qhp.plan_marketing_name}"
      @qhp.plan = nil
    end
  end

  def parse_nation_wide_and_dc_in_network
    if @qhp.national_network.downcase.strip == "yes"
      ["true", "false"]
    else
      ["false", "true"]
    end
  end

  def create_plan_from_serff_data
    @qhp.qhp_cost_share_variances.each do |cost_share_variance|
      if cost_share_variance.hios_plan_and_variant_id.split("-").last != "00"
        if cost_share_variance.plan_marketing_name[-2..-1] != "RE" # dont import plans ending with RE (Religious Exemption)
          csr_variant_id = parse_metal_level == "dental" ? "" : /#{cost_share_variance.hios_plan_and_variant_id.split('-').last}/
          plan = Plan.where(active_year: @plan_year,
            hios_id: /#{@qhp.standard_component_id.strip}/,
            hios_base_id: /#{cost_share_variance.hios_plan_and_variant_id.split('-').first}/,
            csr_variant_id: csr_variant_id).to_a
          next if plan.present?
          new_plan = Plan.new(
            name: @qhp.plan_marketing_name.squish!,
            hios_id: cost_share_variance.hios_plan_and_variant_id,
            hios_base_id: cost_share_variance.hios_plan_and_variant_id.split("-").first,
            csr_variant_id: cost_share_variance.hios_plan_and_variant_id.split("-").last,
            active_year: @plan_year,
            metal_level: parse_metal_level,
            market: parse_market,
            ehb: @qhp.ehb_percent_premium,
            # carrier_profile_id: "53e67210eb899a460300000d",
            carrier_profile_id: get_carrier_id(@carrier_name),
            coverage_kind: @qhp.dental_plan_only_ind.downcase == "no" ? "health" : "dental",
            dental_level: @dental_metal_level
            )
          if new_plan.valid?
            new_plan.save!
          end
        end
      end
    end
  end

  def parse_metal_level
    return @qhp.metal_level unless ["high","low"].include?(@qhp.metal_level.downcase)
    @qhp.metal_level = "dental"
  end

  def parse_market
    @qhp.market_coverage = @qhp.market_coverage.downcase.include?("shop") ? "shop" : "individual"
  end

  def get_carrier_id(name)
    CarrierProfile.find_by_legal_name(name)
  end

  def build_qhp
    @qhp = Products::Qhp.where(active_year: qhp_params[:active_year], standard_component_id: qhp_params[:standard_component_id]).first
    if @qhp.present?
      @qhp.attributes = qhp_params
      @qhp.qhp_benefits = []
      @qhp.qhp_cost_share_variances = []
    else
      @qhp = Products::Qhp.new(qhp_params)
    end
  end

  def build_benefits
    benefits_params.each { |benefit| @qhp.qhp_benefits.build(benefit) }
  end

  def build_cost_share_variances_list
    cost_share_variance_list_params.each do |csvp|
      @csvp = csvp
      next if hios_plan_and_variant_id.split("-").last == "00"
      update_hsa_eligibility
      build_cost_share_variance
    end
  end

  def update_hsa_eligibility
    if hios_plan_and_variant_id.split("-").last == "01" && @qhp.active_year > 2015
      @qhp.hsa_eligibility = hsa_params[:hsa_eligibility]
    end
  end

  def build_cost_share_variance
    build_sbc_params
    build_moops
    build_service_visits
    build_deductible
  end

  def build_deductible
    @csv.build_qhp_deductable(deductible_params)
  end

  def build_service_visits
    service_visits_params.each do |svp|
      @csv.qhp_service_visits.build(svp)
    end
  end

  def build_moops
    maximum_out_of_pockets_params.each do |moop|
      @csv.qhp_maximum_out_of_pockets.build(moop)
    end
  end

  def build_sbc_params
    @csv = if sbc_params
      @qhp.qhp_cost_share_variances.build(cost_share_variance_attributes.merge(sbc_params))
    else
      @qhp.qhp_cost_share_variances.build(cost_share_variance_attributes)
    end
  end

  def hios_plan_and_variant_id
    cost_share_variance_attributes[:hios_plan_and_variant_id]
  end

  def hsa_params
    @csvp[:hsa_attributes]
  end

  def service_visits_params
    @csvp[:service_visits_attributes]
  end

  def deductible_params
    @csvp[:deductible_attributes]
  end

  def maximum_out_of_pockets_params
    @csvp[:maximum_out_of_pockets_attributes]
  end

  def sbc_params
    @csvp[:sbc_attributes]
  end

  def cost_share_variance_attributes
    @csvp[:cost_share_variance_attributes]
  end

  def cost_share_variance_list_params
    @plan[:cost_share_variance_list_attributes]
  end

  def benefits_params
    @plans[:benefits_list][:benefits]
  end

  def qhp_params
    header_params.merge(plan_attribute_params)
  end

  def header_params
    @plans[:header]
  end

  def plan_attribute_params
    assign_active_year_to_qhp
    @plan[:plan_attributes]
  end

  def assign_active_year_to_qhp
    @plan[:plan_attributes][:active_year] = @plan[:plan_attributes][:plan_effective_date][-4..-1].to_i
  end

end
