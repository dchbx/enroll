module BenefitMarkets
  module RulesEngine
    class SubscriberPolicy < Policy

      rule :is_of_age,
        validate: lambda { |c| c.get(:person).age_on(Date.today) > 18 },
        failure: lambda { |c| c.add_error(:person, "must be 18 years of age") },
        requires: [:person]

        rule :is_tobacco_user,
          validate: lambda { |c| c.get(:person).is_tobacco_user == "no" },
          failure: lambda { |c| c.add_error(:person, "is_tobacco_user") },
          requires: [:person]


      def self.call(person)
        context = PolicyExecutionContext.new(person: person)
        self.new.evaluate(context)
        context
      end

    end
  end
end
