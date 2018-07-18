module SponsoredBenefits
  module BenefitSponsorships
    class Account
      include Mongoid::Document


      def self.retrieve_employers_eligible_for_binder_paid
        date = TimeKeeper.date_of_record.end_of_month + 1.day
        all_employers_by_plan_year_start_on_and_valid_plan_year_statuses(date)
      end

    end
  end
end
