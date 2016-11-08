class QhpRateBuilder

  INVALID_PLAN_IDS = ["78079DC0320003","78079DC0320004","78079DC0340002","78079DC0330002"]
  METLIFE_HIOS_IDS = ["43849DC0090001", "43849DC0080001"]

  def initialize
    @rates_array = []
    @action = "new"
  end

  def add(rates_hash, action)
    @rates_array = @rates_array + rates_hash[:items]
    @action = action
  end

  def run
    @results = Hash.new{|results,k| results[k] = []}
    @rates_array.each do |rate|
      @rate = rate
      build_premium_tables
    end
    if @action == "new"
      find_plan_and_create_premium_tables
    else
      find_plan_and_update_premium_tables
    end
  end

#metlife has a different format for importing rate templates.
  def calculate_and_build_metlife_premium_tables
    (20..65).each do |metlife_age|
      @metlife_age = metlife_age
      key = "#{@rate[:plan_id]},#{@rate[:effective_date].to_date.year}"
      @results[key] << {
        age: metlife_age,
        start_on: @rate[:effective_date],
        end_on: @rate[:expiration_date],
        cost: calculate_metlife_cost
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
      @results[key] << {
        age: assign_age,
        start_on: @rate[:effective_date],
        end_on: @rate[:expiration_date],
        cost: @rate[:primary_enrollee]
      }
    end
  end

  def assign_age
    case(@rate[:age_number])
    when "0-20"
      20
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
            pt = pts.where(age: value[:age], start_on: value[:start_on], end_on: value[:end_on]).first
            pt.cost = value[:cost]
            pt.save
          end
        end
      end
    end
  end

end
