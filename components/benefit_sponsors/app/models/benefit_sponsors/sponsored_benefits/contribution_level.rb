module BenefitSponsors
  module SponsoredBenefits
    class ContributionLevel
      include Mongoid::Document
      include Mongoid::Timestamps


      embedded_in :sponsor_contribution,
                  class_name: "BenefitSponsors::SponsoredBenefits::SponsorContribution"

      field :display_name, type: String
      field :contribution_unit_id, type: BSON::ObjectId
      field :is_offered, type: Boolean
      field :order, type: Integer
      field :contribution_factor, type: Float
      field :min_contribution_factor, type: Float
      field :contribution_cap, type: Float
      field :flat_contribution_amount, type: Float

      delegate :contribution_model, to: :sponsor_contribution

      validates_presence_of :display_name, :allow_blank => false
      validates_presence_of :contribution_unit_id, :allow_blank => false
      validates_presence_of :contribution_factor, :allow_blank => false

      def contribution_pct
        (contribution_factor * 100).round(2)
      end

      def offered?
        is_offered
      end

      def contribution_unit
        return @contribution_unit if defined? @contribution_unit
        @contribution_unit = contribution_model.find_contribution_unit(contribution_unit_id)
      end

      # We are setting the minimum contribution factor from the latest contribution model
      # Because the eligiblity around minimum contribution might change every year
      def renew_from(current_contribution_level, new_contribution_model)
        new_cu = new_contribution_model.contribution_units.detect { |contribution_unit| contribution_unit.display_name == display_name }
        if current_contribution_level.present?
          self.is_offered = current_contribution_level.is_offered
          self.contribution_factor = current_contribution_level.contribution_factor
          self.min_contribution_factor = new_cu.minimum_contribution_factor
          self.contribution_cap = current_contribution_level.contribution_cap
          self.flat_contribution_amount = current_contribution_level.flat_contribution_amount
        end
      end
    end
  end
end
