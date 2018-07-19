date = Date.today

if date.day > 15
  window_start = Date.new(date.year,date.month,16)
  window_end = Date.new(date.next_month.year,date.next_month.month,15)
  window = (window_start..window_end)
elsif date.day <= 15
  window_start = Date.new((date - 1.month).year,(date - 1.month).month,16)
  window_end = Date.new(date.year,date.month,15)
  window = (window_start..window_end)
end

start_on_date = window.end.next_month.beginning_of_month.to_time.utc.beginning_of_day

def find_renewed_sponsorships(start_date)
  BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where({
    "benefit_applications" => {
      "$elemMatch" => {
        "effective_period.min" => start_date,
        # "predecessor_id" => {"$ne" => nil},
        "aasm_state" => {"$in" => [
          :enrollment_open,
          :enrollment_closed,
          :enrollment_eligible,
          :active
        ]}
      }
    }
  })
end

renewed_sponsorships = find_renewed_sponsorships(start_on_date)

f = File.open("policies_to_pull.txt","w")

renewed_sponsorships.each do |bs|
  fein = bs.profile.organization.fein
  selected_application = bs.benefit_applications.detect do |ba|
    (!ba.predecessor_id.blank?) &&
      (ba.start_on == start_on_date) &&
      [:enrollment_open,
        :enrollment_closed,
        :enrollment_eligible,
        :active].include?(ba.aasm_state)
  end

  employer_enrollment_query = ::Queries::NamedEnrollmentQueries.find_simulated_renewal_enrollments(selected_application.sponsored_benefits, start_on_date)
  employer_enrollment_query.each do |enrollment_hbx_id|
    f.puts(enrollment_hbx_id)
  end
end