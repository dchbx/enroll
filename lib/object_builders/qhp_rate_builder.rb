class QhpRateBuilder

  INVALID_PLAN_IDS = ["78079DC0320003","78079DC0320004","78079DC0340002","78079DC0330002"]
  METLIFE_HIOS_IDS = ["43849DC0090001", "43849DC0080001"]

  def initialize
    @rates_array = []
    @results_array = []
    @rating_area_id_cache = {}
    @rating_area_cache = {}
    @premium_table_cache = Hash.new {|h, k| h[k] = Hash.new}
    @action = "new"
  end

  def set_rating_area_cache
    ::BenefitMarkets::Locations::RatingArea.all.each do |ra|
      @rating_area_id_cache[[ra.active_year, ra.exchange_provided_code]] = ra.id
      @rating_area_cache[ra.id] = ra
    end
  end

  def add(rates_hash, action, year)
    set_rating_area_cache
    if year < 2018
      @rates_array = @rates_array + rates_hash[:items]
      @action = action
    else
      rates_hash[:plan_rate_group_attributes].each do |rate_group_attributes|
        @rates_array = @rates_array + rate_group_attributes[:items]
        @action = action
      end
    end
  end

  def run
    @results = Hash.new{|results,k| results[k] = []}
    @rates_array.each do |rate|
      @rate = rate
      build_premium_tables
      build_product_premium_tables
    end
    if @action == "new"
      find_plan_and_create_premium_tables
      find_product_and_create_premium_tables
    else
      find_plan_and_update_premium_tables
    end
  end

#metlife has a different format for importing rate templates.
  def calculate_and_build_metlife_premium_tables
    (20..65).each do |metlife_age|
      @metlife_age = metlife_age
      key = "#{@rate[:plan_id]},#{@rate[:effective_date].to_date.year}"
      rating_area = Settings.aca.state_abbreviation.upcase == "MA" ? @rate[:rate_area_id].gsub("Rating Area ", "R-MA00") : nil
      @results[key] << {
        age: metlife_age,
        start_on: @rate[:effective_date],
        end_on: @rate[:expiration_date],
        cost: calculate_metlife_cost,
        rating_area: rating_area
      }
    end
  end

  def calculate_metlife_cost
    if @metlife_age == 20
      (@rate[:primary_enrollee_one_dependent].to_f - @rate[:primary_enrollee].to_f).round(2)
    else
      @rate[:primary_enrollee].to_f
    end
  end

  def build_premium_tables
    if METLIFE_HIOS_IDS.include?(@rate[:plan_id])
      calculate_and_build_metlife_premium_tables
    else
      key = "#{@rate[:plan_id]},#{@rate[:effective_date].to_date.year}"
      rating_area = Settings.aca.state_abbreviation.upcase == "MA" ? @rate[:rate_area_id].gsub("Rating Area ", "R-MA00") : "R-DC001"
      @results[key] << {
        age: assign_age,
        start_on: @rate[:effective_date],
        end_on: @rate[:expiration_date],
        cost: @rate[:primary_enrollee],
        rating_area: rating_area
      }
    end
  end

  def find_product_and_create_premium_tables
    @results_array.uniq.each do |value|
      hios_id, year = value.split(",")
      products = ::BenefitMarkets::Products::Product.where(hios_id: /#{hios_id}/).select{|a| a.active_year.to_s == year.to_s}
      products.each do |product|
        product.premium_tables = nil
        product.save
      end
    end
    @premium_table_cache.each_pair do |k, v|
      product_hios_id, rating_area_id, applicable_range = k
      premium_tables = []
      premium_tuples = []

      v.each_pair do |pt_age, pt_cost|
        premium_tuples << ::BenefitMarkets::Products::PremiumTuple.new(
          age: pt_age,
          cost: pt_cost
        )
      end

      premium_tables << ::BenefitMarkets::Products::PremiumTable.new(
        effective_period: applicable_range,
        rating_area: @rating_area_cache[rating_area_id],
        rating_area_id: rating_area_id,
        premium_tuples: premium_tuples
      )

      active_year = applicable_range.first.year
      products = ::BenefitMarkets::Products::Product.where(hios_id: /#{product_hios_id}/).select{|a| a.active_year == active_year}
      products.each do |product|
        product.premium_tables << premium_tables
        product.premium_ages = premium_tuples.map(&:age).minmax
        product.save
      end
    end
  end

  def build_product_premium_tables
    active_year = @rate[:effective_date].to_date.year
    applicable_range = @rate[:effective_date].to_date..@rate[:expiration_date].to_date
    rating_area = Settings.aca.state_abbreviation.upcase == "MA" ? @rate[:rate_area_id].gsub("Rating Area ", "R-MA00") : nil
    rating_area_id = @rating_area_id_cache[[active_year, rating_area]]
    @premium_table_cache[[@rate[:plan_id], rating_area_id, applicable_range]][assign_age] = @rate[:primary_enrollee]
    @results_array << "#{@rate[:plan_id]},#{active_year}"
  end

  def assign_age
    case(@rate[:age_number])
    when "0-14"
      14
    when "0-20"
      20
    when "64 and over"
      64
    when "65 and over"
      65
    else
      @rate[:age_number].to_i
    end
  end

  def find_plan_and_create_premium_tables
    @results.each do |key, premium_tables|
      hios_id, year = key.split(",")
      unless INVALID_PLAN_IDS.include?(hios_id)
        @plans = Plan.where(hios_id: /#{hios_id}/, active_year: year)
        @plans.each do |plan|
          plan.premium_tables = nil
          plan.premium_tables.create!(premium_tables)
          plan.minimum_age, plan.maximum_age = plan.premium_tables.map(&:age).minmax
          plan.save
        end
      end
    end
  end

  def find_plan_and_update_premium_tables
    @results.each do |key, premium_tables|
      hios_id, year = key.split(",")
      unless INVALID_PLAN_IDS.include?(hios_id)
        @plans = Plan.where(hios_id: /#{hios_id}/, active_year: year)
        @plans.each do |plan|
          pts = plan.premium_tables
          premium_table_hash.each do |value|
            pt = pts.where(age: value[:age], start_on: value[:start_on], end_on: value[:end_on], rating_area: value[:rating_area]).first
            pt.cost = value[:cost]
            pt.save
          end
        end
      end
    end
  end

end