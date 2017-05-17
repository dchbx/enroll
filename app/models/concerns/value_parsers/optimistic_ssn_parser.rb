module ValueParsers
  # NOTE: This class is designed for optimistic parsing.  Given a value it
  #       assumes that it most likely contains an SSN.  This is useful for
  #       cases such as importing spreadsheets - but *DO NOT* use this in
  #       models which validate user input.
  class OptimisticSsnParser
    def self.on(*method_names)
      new_mod = Module.new do 
        def self.included(klass)
          ::ValueParsers::OptimisticSsnParser.define_ssn_parse_method(klass)
        end
      end
      method_names.each do |method_name|
      new_mod.class_eval(<<-RUBYCODE)
        def #{method_name}=(val)
          @#{method_name} = __parse_ssn_value(val)
        end
      RUBYCODE
      end
      new_mod
    end

    def self.define_ssn_parse_method(klass)
      unless klass.instance_methods.include?(:__parse_ssn_value)
        klass.class_eval do
          def __parse_ssn_value(val)
            return nil if val.blank?
            as_string = val.to_s.split(".").first.strip
            return nil if as_string.blank?
            justified_string = as_string.gsub(/\D/, "").rjust(9, "0")
            return nil if justified_string == "000000000"
            return nil if justified_string == "999999999"
            justified_string
          end
        end
      end
    end
  end
end
