module BenefitSponsors
  module Forms
    class ContributionLevelForm

      include Virtus.model
      include ActiveModel::Model

      attribute :id, String
      attribute :display_name, String
      attribute :contribution_unit_id, String
      attribute :is_offered, Boolean
      attribute :order, Integer
      attribute :contribution_factor, Float
      attribute :min_contribution_factor, Float
      attribute :contribution_cap, Float
      attribute :flat_contribution_amount, Float

      validates_presence_of :contribution_factor

      def self.for_new(params)
        contribution_levels(params[:contribution_model]).collect do |level_attrs|
          form = self.new(level_attrs)
          form
        end
      end

      def is_offered=(val)
        is_offered = is_employee_cl ? "true" : val
        super is_offered
      end

      def self.contribution_levels(contribution_model = nil)
        # TODO: query contribution model based on market
        contribution_model ||= BenefitMarkets::ContributionModels::ContributionModel.all.first
        return [] unless contribution_model
        contribution_model.contribution_units.inject([]) do |data, unit|
          data << { display_name: unit.display_name,
            is_offered: true,
            order: unit.order,
            min_contribution_factor: unit.minimum_contribution_factor,
            contribution_factor: unit.default_contribution_factor, 
          }  
        end
      end

      def is_employee_cl
        display_name == "Employee" || display_name == "Employee Only"
      end
    end
  end
end
