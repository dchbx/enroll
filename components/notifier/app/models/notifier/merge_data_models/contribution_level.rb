# frozen_string_literal: true

module Notifier
  module MergeDataModels
    class ContributionLevel
      include Virtus.model

      attribute :display_name, String
      attribute :contribution_pct, Integer

      def self.stubbed_object
        con_level = {
          'Employee' => 80,
          'Spouse' => 80,
          'Domestic Partner' => 80,
          'Child Under 26' => 80
        }
        con_level.collect do |k, v|
          Notifier::MergeDataModels::ContributionLevel.new(
            {
              display_name: k,
              contribution_pct: v
            }
          )
        end
      end
    end
  end
end