module BenefitSponsors
  module Queries
    class NoticeQueries

      def self.initial_employers_by_effective_on_and_state(start_on: TimeKeeper.date_of_record, aasm_state:)
        BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where({
          :'benefit_applications' => {
            :$elemMatch => {
               :"effective_period.min" => start_on,
               :aasm_state => aasm_state
            }
          }
        })
      end

      def self.organizations_for_force_publish(new_date)
        BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where({
          :'benefit_applications' =>
          { :$elemMatch => {
            :"effective_period.min" => new_date.next_month.beginning_of_month,
            :aasm_state => :draft
          }}
        })
      end

      def self.organizations_for_low_enrollment_notice(current_date)
        BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where({
          :"benefit_applications" => { 
            :$elemMatch => {
              :"aasm_state" => :enrollment_open,
              :"open_enrollment_period.max" => current_date + 2.days
            }
          }
        })
      end

      def self.initial_employers_in_enrolled_state
        BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where({
          :"benefit_applications" => { 
            :$elemMatch => {
              :"aasm_state" => :enrollment_closed,
            }
          }
        })
      end
    end
  end
end