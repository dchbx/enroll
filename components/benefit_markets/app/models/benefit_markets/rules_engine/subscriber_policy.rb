# frozen_string_literal: true

module BenefitMarkets
  module RulesEngine
    class SubscriberPolicy < Policy

      # Date.today converted to TimeKeeper.date_of_record
      rule :is_of_age,
           validate: ->(c) { c.get(:person).age_on(TimeKeeper.date_of_record > 18) },
           failure: ->(c) { c.add_error(:person, "must be 18 years of age") },
           requires: [:person]

      rule :is_tobacco_user,
           validate: ->(c) { c.get(:person).is_tobacco_user == "no" },
           failure: ->(c) { c.add_error(:person, "is_tobacco_user") },
           requires: [:person]


      def self.call(person)
        context = PolicyExecutionContext.new(person: person)
        self.new.evaluate(context)
        context
      end

    end
  end
end
