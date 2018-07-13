module Caches
  class SicCodesCache

    def self.load
      self.grouped_sic_codes
    end

    private

    def self.grouped_sic_codes
      @@grouped_sic_codes ||= {}
      if @@grouped_sic_codes.empty?
        SicCode.all.group_by(&:industry_group_label).each do |industry_group_label, sic_codes|
          @@grouped_sic_codes[industry_group_label] = sic_codes.collect{|sc| ["#{sc.sic_label} - #{sc.sic_code}", sc.sic_code]}
        end
      end
      @@grouped_sic_codes
    end
  end
end
