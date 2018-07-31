# This rake task will trigger notice to employers by taking either hbx_ids or employer_ids or feins and event_name
# Running the task with arguments from command line
# Ex: rake notice:shop_employer_notice_event hbx_ids="1231 121 1567" feins="42112 12123 123123" employer_ids = "123123 12312312 123123123" event="specific_event"
namespace :notice do
  desc "Generate shop employer notices"
  task :shop_employer_notice_event => :environment do |task, args|

    @employer_ids = ENV['employer_ids']
    @hbx_ids = ENV['hbx_ids']
    @feins = ENV['feins']
    @event_name = ENV['event']

    if @event_name
      case
      when @employer_ids
        @employer_ids.split(' ').each do |employer_id|
          employer_profile = EmployerProfile.find(employer_id)
          trigger_notice(employer_profile) if employer_profile
          puts "#{@event_name} - notice triggered successfully for employer_id - #{employer_id}" unless Rails.env.test?
        end
      when @hbx_ids
        @hbx_ids.split(' ').each do |hbx_id|
          employer_profile = Organization.where(hbx_id: hbx_id).first.employer_profile
          trigger_notice(employer_profile) if employer_profile
          puts "#{@event_name} - notice triggered successfully for #{hbx_id}" unless Rails.env.test?
        end
      when @feins
        @feins.split(' ').each do |fein_id|
          employer_profile = Organization.where(fein: fein_id).first.employer_profile
          trigger_notice(employer_profile) if employer_profile
          puts "#{@event_name} - notice triggered successfully for fein_id - #{fein_id}" unless Rails.env.test?
        end
      else
        puts "Please provide either hbx_id or feins as arguments" unless Rails.env.test?
      end
    end
  end

  def trigger_notice(employer_profile)
    observer = Observers::NoticeObserver.new
    plan_year = employer_profile.plan_years.first
    observer.deliver(recipient: employer_profile, event_object: plan_year, notice_event: @event_name)
  end
end