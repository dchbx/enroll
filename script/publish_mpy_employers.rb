FEIN_LIST = %w(

)

class MpyNotifier
  extend Acapi::Notifiers

  def self.send_mpy_notification(fein)
    org = BenefitSponsors::Organizations::Organization.where(fein: fein).first
    notify(
        "acapi.info.events.employer.benefit_coverage_mid_plan_year_initial_eligible",
        {
          "employer_id" => org.hbx_id
        }
    )
  end
end

FEIN_LIST.each do |fein|
  MpyNotifier.send_mpy_notification(fein.strip)
end
