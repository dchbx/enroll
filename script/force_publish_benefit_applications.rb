# Renew everybody who needs to be renewed

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

def find_renewable_benefit_applications(start_date, already_renewed_ids)
  BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where({
    "benefit_applications" => {
      "$elemMatch" => {
        "effective_period.min" => start_date,
        "predecessor_id" => {"$ne" => nil},
        "aasm_state" => {"$in" => [
          :draft,
          :approved
        ]}
      }
    },
    "_id" => {"$nin" => already_renewed_ids}
  })
end

benefit_applications = []

force_renewal_eligible = find_renewable_benefit_applications(
  start_on_date,
  find_renewed_sponsorships(start_on_date).pluck("_id")
)

force_renewal_eligible.each do |bs|
  selected_application = bs.benefit_applications.detect do |ba|
    (!ba.predecessor_id.blank?) &&
      (ba.start_on == start_on_date)
  end
  begin
    selected_application.simulate_provisional_renewal! if selected_application.may_simulate_provisional_renewal?
  rescue Exception => e
    puts "Could not force publish #{selected_application.benefit_sponsorship.organization.legal_name} because of #{e.inspect}"
    next
  end
end
