# Running the task with arguments from command line
# Ex: rake notice:shop_employer_notice['541634423 483756347865',initial_shop_application_approval]

namespace :notice do
  desc "Generate shop employer notices"
  task :shop_employer_notice, [:feins, :event_name, :state] => :environment do |task, args|
    @feins = args[:feins].split(" ")
    @event_name = args[:event_name].to_s
    @options = args[:state].to_s
    @state_options = {:state => @options}
    if @feins.present? && @event_name.present?
      @feins.each do |fein|
        begin
          organization = BenefitSponsors::Organizations::Organization.where(fein: fein).first
          employer_profile = organization.employer_profile
          benefit_application = organization.active_benefit_sponsorship.benefit_applications.where(:aasm_state.in => ["draft", "approved"]).first
          service = BenefitSponsors::Services::NoticeService.new
          service.deliver(recipient: employer_profile, event_object: benefit_application, notice_event: @event_name, notice_params: @state_options)
        rescue Exception => e
          Rails.logger.error { "Failed to deliver #{@event_name} notice to fein- #{fein} due to #{e}" }
        end
      end
    else
      Rails.logger.error { "shop_employer_notice: invalid arguments." } unless Rails.env.test?
    end
  end
end
