module ConfigurableModel
  class Relation

    attr_accessor :class_name

    def initialize(class_name)
      @class_name = class_name
    end

    def base_klass # BenefitMarkets::BenefitMarket
      class_name.to_s
    end

    def setting_klass # BenefitMarketSetting
      base_klass.demodulize + "Setting"
    end

    def base_relation # benefit_market
      base_klass.demodulize.underscore
    end

    def setting_relation # benefit_market_settings
      "#{setting_klass.underscore}s"
    end

    def base_klass_name_space
      base_klass.deconstantize
    end

    def setting_klass_with_module
      [base_klass_name_space, setting_klass].join("::")
    end

    def setting_collection
      [base_klass_name_space.underscore.gsub('/', '_'), setting_relation].join('_')
    end
  end
end