module ValueParsers
  class SsnParser
    def self.parse(val)
      return nil if val.blank?
      as_string = val.to_s.split(".").first.strip
      return nil if as_string.blank?
      justified_string = as_string.gsub(/\D/, "").rjust(9, "0")
      return nil if justified_string == "000000000"
      justified_string
    end
  end
end
