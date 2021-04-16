class ProductBuilder
  INVALID_PLAN_IDS = ["88806MA0020005", "88806MA0040005", "88806MA0020051",
  "18076MA0010001", "80538MA0020001", "80538MA0020002", "11821MA0020001", "11821MA0040001"] # These plan ids are suppressed and we dont save these while importing.
  LOG_PATH = "#{Rails.root}/log/rake_xml_import_products_#{Time.now.to_s.gsub(' ', '')}.log"

  def initialize(qhp_hash)
    @log_path = LOG_PATH
    @qhp_hash = qhp_hash
    @qhp_array = []
    @rating_area_model = EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model).item
    @state_abbreviation = EnrollRegistry[:enroll_app].setting(:state_abbreviation).item
    set_issuer_profile_hash
    set_service_areas
    FileUtils.mkdir_p(File.dirname(@log_path)) unless File.directory?(File.dirname(@log_path))
    @logger = Logger.new(@log_path)
  end

  def add(qhp_hash)
    @qhp_array += qhp_hash[:packages_list][:packages]
  end

  def run
    @xml_plan_counter, @success_plan_counter = 0,0
    @existing_qhp_counter = 0
    iterate_plans
    show_qhp_stats unless Rails.env.test?
  end

  def iterate_plans
    @qhp_array.each do |products|
      @products = products
      @xml_plan_counter += products[:plans_list][:plans].size
      products[:plans_list][:plans].each do |product|
        @product = product
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
    puts "Total Number of Products imported from xml: #{@xml_plan_counter}."
    puts "Total Number of Products Saved to database: #{@success_plan_counter}."
    puts "Total Number of Existing Products : #{@existing_qhp_counter}."
    puts "Check the log file #{@log_path}"
    puts "*"*80
    @logger.info "\nTotal Number of Plans imported from xml: #{@xml_plan_counter}.\n"
    @logger.info "\nTotal Number of Plans Saved to database: #{@success_plan_counter}.\n"
  end

  def validate_and_persist_qhp
    begin
      if !INVALID_PLAN_IDS.include?(@qhp.standard_component_id.strip)
        associate_product_with_qhp
        @qhp.save!
      end
      @logger.info "\nSaved Plan: #{@qhp.plan_marketing_name}, hios product id: #{@qhp.standard_component_id} \n"
    rescue Exception => e
      @logger.error "\n Failed to create plan: #{@qhp.plan_marketing_name}, \n hios product id: #{@qhp.standard_component_id} \n Exception Message: #{e.message} \n\n Errors: #{@qhp.errors.full_messages} \n\n Backtrace: #{e.backtrace.join("\n            ")}\n ******************** \n"
    end
  end

  def associate_product_with_qhp
    effective_date = @qhp.plan_effective_date.to_date
    @qhp.plan_effective_date = effective_date.beginning_of_year
    @qhp.plan_expiration_date = effective_date.end_of_year

    create_product_from_serff_data
  end

  def build_product_attributes(benefit_market_kind = nil)
    shared_attributes = {
      benefit_market_kind: benefit_market_kind || "aca_#{parse_market}",
      title: @cost_share_variance.plan_marketing_name.squish!,
      issuer_profile_id: get_issuer_profile_id,
      hios_id: is_health_product? ? @cost_share_variance.hios_plan_and_variant_id : @hios_base_id,
      hios_base_id: @hios_base_id,
      csr_variant_id: @csr_variant_id,
      application_period: (Date.new(@qhp.active_year, 1, 1)..Date.new(@qhp.active_year, 12, 31)),
      service_area_id: mapped_service_area_id,
      deductible: @cost_share_variance.qhp_deductable.in_network_tier_1_individual,
      family_deductible: @cost_share_variance.qhp_deductable.in_network_tier_1_family,
      is_reference_plan_eligible: true,
      metal_level_kind: retrieve_metal_level.to_sym
    }

    if is_health_product?
      {
        health_plan_kind: @qhp.plan_type.downcase,
        ehb: @qhp.ehb_percent_premium.presence || 1.0,
        product_package_kinds: [:metal_level, :single_issuer, :single_product]
      }
    else
      {
        dental_plan_kind: @qhp.plan_type.downcase,
        dental_level: @qhp.metal_level.downcase,
        product_package_kinds: [:multi_product, :single_issuer]
      }
    end.merge(shared_attributes)
  end

  def create_product_from_serff_data
    @qhp.qhp_cost_share_variances.each do |cost_share_variance|
      @cost_share_variance = cost_share_variance
      @hios_base_id, @csr_variant_id = cost_share_variance.hios_plan_and_variant_id.split("-")
      next if @csr_variant_id == "00"

      @csr_variant_id = retrieve_metal_level == "dental" ? "" : @csr_variant_id
      products = ::BenefitMarkets::Products::Product.by_year(@qhp.active_year).where(
        hios_base_id: @hios_base_id,
        csr_variant_id: @csr_variant_id
      )
      if products.exists?
        products.each do |product|

          all_attributes = build_product_attributes(product.benefit_market_kind)
          product.update_attributes(all_attributes)
          @existing_qhp_counter += 1
        end
      else
        all_attributes = build_product_attributes
        new_product = if is_health_product?
                        ::BenefitMarkets::Products::HealthProducts::HealthProduct.new(all_attributes)
                      else
                        ::BenefitMarkets::Products::DentalProducts::DentalProduct.new(all_attributes)
                      end
        if new_product.valid?
          new_product.save!
          create_congressional_products(new_product)
          @success_plan_counter += 1
          cost_share_variance.product_id = new_product.id
        else
          @logger.error "\n Failed to create product: #{new_product.title}, \n hios product id: #{new_product.hios_id}\n Errors: #{new_product.errors.full_messages}\n ******************** \n"
        end
      end
    end
  end

  def create_congressional_products(new_product)
    if new_product.benefit_market_kind == :aca_shop && new_product.metal_level_kind == :gold
      congress_product = new_product.dup
      congress_product.benefit_market_kind = "fehb".to_sym
      congress_product.save!
    else
      new_product
    end
  end

  def get_issuer_profile_id
    @issuer_profile_hash[@qhp.standard_component_id[0..4]]
  end

  def set_issuer_profile_hash
    @issuer_profile_hash = {}
    exempt_organizations = ::BenefitSponsors::Organizations::Organization.issuer_profiles
    exempt_organizations.each do |exempt_organization|
      issuer_profile = exempt_organization.issuer_profile
      issuer_profile.issuer_hios_ids.each do |issuer_hios_id|
        @issuer_profile_hash[issuer_hios_id] = issuer_profile.id.to_s
      end
    end
    @issuer_profile_hash
  end

  def mapped_service_area_id
    if @rating_area_model == 'single'
      @service_area_map[[get_issuer_profile_id.to_s,"#{@state_abbreviation}S001",@qhp.active_year]]
    else
      @service_area_map[[@qhp.issuer_id,get_issuer_profile_id.to_s,@qhp.service_area_id,@qhp.active_year]]
    end
  end

  def set_service_areas
    @service_area_map = {}
    ::BenefitMarkets::Locations::ServiceArea.all.map do |sa|
      if @rating_area_model == 'single'
        @service_area_map[[sa.issuer_profile_id.to_s,sa.issuer_provided_code,sa.active_year]] = sa.id
      else
        @service_area_map[[sa.issuer_hios_id, sa.issuer_profile_id.to_s,sa.issuer_provided_code,sa.active_year]] = sa.id
      end
    end
  end

  def is_health_product?
    @qhp.dental_plan_only_ind.downcase == "no"
  end

  def retrieve_metal_level
    is_health_product? ? @qhp.metal_level.downcase : "dental"
  end

  def parse_market
    @qhp.market_coverage = @qhp.market_coverage.downcase.include?("shop") ? "shop" : "individual"
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
    @product[:cost_share_variance_list_attributes]
  end

  def benefits_params
    @products[:benefits_list][:benefits]
  end

  def qhp_params
    header_params.merge(product_attribute_params)
  end

  def header_params
    @products[:header]
  end

  def product_attribute_params
    assign_active_year_to_qhp
    @product[:plan_attributes]
  end

  def assign_active_year_to_qhp
    @product[:plan_attributes][:active_year] = @product[:plan_attributes][:plan_effective_date][-4..-1].to_i
  end

end