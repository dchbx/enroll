module SponsoredBenefits
  module RatingModels
    class RatingFactor
      include Mongoid::Document
      include Mongoid::Timestamps

      field :key,               type: Symbol
      field :value,             type: Float

      # Return 
      def result
      end

    end
  end
end
