module ConfigurableModel
  module Sources
    class HashSource

      def initialize(hash)
        @hash = hash
      end

      def load(configurable_obj)
        @hash.each do |key, options|
          configurable_obj[key] = options
        end
      end
    end
  end
end