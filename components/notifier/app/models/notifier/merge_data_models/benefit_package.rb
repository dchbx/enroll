# frozen_string_literal: true

module Notifier
  module MergeDataModels
    class BenefitPackage
      include Virtus.model

      attribute :start_on, String
      attribute :title, String
      attribute :sponsored_benefits, Array[MergeDataModels::SponsoredBenefit]

      def self.stubbed_object
        benefit_package = Notifier::MergeDataModels::BenefitPackage.new({start_on: '12/1/2018',
                                                                         title: 'Adams Benefit Package'})
        benefit_package.sponsored_benefits = Notifier::MergeDataModels::SponsoredBenefit.stubbed_object
        benefit_package
      end
    end
  end
end
