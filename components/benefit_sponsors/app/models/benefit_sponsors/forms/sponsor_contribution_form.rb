module BenefitSponsors
  module Forms
    class SponsorContributionForm
      
      include Virtus.model
      include ActiveModel::Model

      attribute :contribution_levels, Array[ContributionLevelForm]
      attr_accessor :contribution_levels

      validates_presence_of :contribution_levels

      def contribution_levels_attributes=(attributes)
        @contribution_levels ||= []
        attributes.each do |i, contribution_level_attributes|
          @contribution_levels.push(ContributionLevelForm.new(contribution_level_attributes))
        end
      end

      def self.for_new(params)
        form = self.new
        form.contribution_levels = ContributionLevelForm.for_new({contribution_model: params[:product_package].contribution_model})
        form
      end

      def min_contributions_map
        contribution_levels.inject({}) {|data, cl| data[cl.display_name] = cl.min_contribution_factor * 100; data;}
      end
    end
  end
end