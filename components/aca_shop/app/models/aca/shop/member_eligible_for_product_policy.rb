module Aca
  module Shop
    # Busines rules for determining if member meets benefit product eligibility requirements
    class MemberEligibleForProductPolicy

      def initialize(member, product, options = {})
        @member  = member
        @product = product
        @benefit_enrollment_members = options[:benefit_enrollment_members]
      end

      def is_eligible?
        @scores = []

        status = eligibility_criteria.reduce(true) do |eligible, rule|
          if self.public_send("is_#{rule}_satisfied?")
            true && eligible
          else
            @scores << ["eligibility failed on #{rule}"]
            false
          end
        end
        return status
      end

      def eligibility_criteria
        @product.member_eligible_for_product_rules.class.fields.keys.reject{|k| k == "_id"}
      end

      def is_age_range_satisfied?
        return true if @benefit_package.age_range == (0..0)

        age = age_on_next_effective_date(@member.dob)
        @benefit_package.age_range.cover?(age)
      end

      def score
        @scores || []
      end

    private
      #TODO: Change this to use benefit
      def age_on_next_effective_date(dob)
        today = TimeKeeper.date_of_record
        today.day <= 15 ? age_on = today.end_of_month + 1.day : age_on = (today + 1.month).end_of_month + 1.day
        age_on.year - dob.year - ((age_on.month > dob.month || (age_on.month == dob.month && age_on.day >= dob.day)) ? 0 : 1)
      end

      def age_on_benefit_end_on(dob, end_on=TimeKeeper.date_of_record)
        # calculate method depend on 6710
        end_on.year - dob.year - ((end_on.month > dob.month || (end_on.month == dob.month && end_on.day >= dob.day)) ? 0 : 1)
      end

    end
  end
end