# frozen_string_literal: true

module BenefitMarkets
  class Products::ProductFactory

    attr_accessor :date, :product, :products

    #initialize with date for has_rates?
    #initialize with product_id to get product
    #initialize with market_kind to get products based on market
    def initialize(options = {})
      @date = options[:date] if options[:date]
      product_for(options[:product_id]) if options[:product_id]
      by_market(options[:market_kind]) if options[:market_kind]
    end

    def has_rates?
      return false if @date.blank?

      date_range = @date.beginning_of_month..@date.end_of_month
      # searches products by date_range, filters with health products and then
      # checks if premium_tables are present for that effective_date.
      ::BenefitMarkets::Products::Product
        .by_application_period(date_range)
        .health_products
        .effective_with_premiums_on(@date)
        .present?
    end

    #initialize with products
    #collect products by coverage kind and year
    # Example coverage kinds:
    #DC "dental", 2019:
    #final query:
    #   products.dental_products.by_year(2019)
    #DC "health", 2019:
    #final query:
    #   products.health_products.by_year(2019)
    def by_coverage_kind_and_year(coverage_kind, active_year)
      products.public_send("#{coverage_kind}_products").by_year(active_year)
    end

    #initialize with products
    #collect products by coverage kind, year and csr
    # Example coverage kinds:
    #   DC "dental", 2019:
    #     .by_coverage_kind_and_year("dental", 2019)
    #   DC "health", 2019, "csr_87":
    #     .by_coverage_kind_and_year("health", 2019,  "csr_87")
    def by_coverage_kind_year_and_csr(coverage_kind, active_year, csr_kind:)
      products_with_premium_tables = by_coverage_kind_and_year(coverage_kind, active_year).with_premium_tables
      products_with_premium_tables = products_with_premium_tables.by_csr_kind_with_catastrophic(csr_kind) if coverage_kind == 'health'
      products_with_premium_tables
    end

    def cost_for(schedule_date, age)
      bound_age_val = bound_age(age)
      value = premium_table_for(schedule_date).first.premium_tuples.detect {|pt| pt.age == bound_age_val}.cost
      BigDecimal(value.to_s).round(2).to_f
    rescue StandardError
      raise [(product.id if product), bound_age_val, schedule_date, age].inspect
    end

    def premium_table_for(date)
      product.premium_tables.select do |pt|
        (pt.effective_period.min <= date) && (pt.effective_period.max >= date)
      end
    end

    private

    def bound_age(age)
      return product.premium_ages.min if age < product.premium_ages.min
      return product.premium_ages.max if age > product.premium_ages.max

      age
    end

    def by_market(market_kind)
      @products = product_klass.public_send("aca_#{market_kind}_market")
    end

    def product_klass
      BenefitMarkets::Products::Product
    end

    def product_for(id)
      @product = product_klass.find(id) if id
    end
  end
end
