module Api
  module V1
    module Mobile
      class BaseUtil

        def initialize args={}
          args.each do |k, v|
            instance_variable_set("@#{k}", v) unless v.nil?
          end
        end

        #
        # Protected
        #
        protected

        def format_date date
          date.strftime('%m-%d-%Y') if date.respond_to?(:strftime)
        end

      end
    end
  end
end