module Queries
  class NoticeQueries

    def self.initial_employers_by_effective_on_and_state(start_on: TimeKeeper.date_of_record, aasm_state:)
      Organization.where(:"employer_profile.plan_years" =>{
        :$elemMatch => {
          :start_on => start_on,
          :aasm_state => aasm_state.to_s
        }})
    end
  end
end