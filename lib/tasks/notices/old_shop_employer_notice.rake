# Running the task with arguments from command line
# Ex: rake notice:shop_employer_notice[5981e03960be9d05c900000b,initial_shop_application_approval]
namespace :notice do
  desc "Generate shop employer notices"
  task :old_shop_employer_notice, [:fein, :event_name, :state] => :environment do |task, args|
    @fein = args[:fein].to_s
    @event_name = args[:event_name].to_s
    @options = args[:state].to_s
    @state_options = {:state => @options}
    if @fein.present? && @event_name.present?
      employer = Organization.where(fein: @fein).first
      employer_id = employer.employer_profile.id.to_s
      if @state_options
        ShopNoticesNotifierJob.perform_later(employer_id, @event_name, @state_options) if employer
      else
        ShopNoticesNotifierJob.perform_later(employer_id, @event_name) if employer
      end
    else
      Rails.logger.error "shop_employer_notice: invalid arguments."
    end
  end
end
