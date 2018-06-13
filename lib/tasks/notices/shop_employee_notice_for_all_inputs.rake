# This rake task will trigger notice to employers by taking either hbx_ids or employer_ids  and event_name
# Running the task with arguments from command line
# Ex: rake notice:shop_employee_notice_event hbx_ids="1231 121 1567" employee_ids = "123123 12312312 123123123" event="specific_event"
namespace :notice do
  desc "Generate shop employee notices"
  task :shop_employee_notice_event => :environment do |task, args|
    @employee_ids = ENV['employee_ids'].try(:split, " ")
    @hbx_ids = ENV['hbx_ids'].try(:split, " ")
    @event_name = ENV['event']
    if @event_name
      case
        when @employee_ids
          @employee_ids.each do | employee_id |
            census_record = CensusEmployee.find(employee_id)
            ShopNoticesNotifierJob.perform_later(census_record.id.to_s, @event_name) if census_record
          end
        when @hbx_ids
          @hbx_ids.each do |hbx_id|
            record = Person.where(hbx_id: hbx_id).first
            census_employee_id = record.employee_roles.first.census_employee_id.to_s
            if record.has_active_employee_role?
              ShopNoticesNotifierJob.perform_later(census_employee_id, @event_name) if census_employee_id
              puts "Notice Triggered Successfully"
            end
          end
        else
          puts "Please provide either hbx_id or census_employee _id as arguments"
      end
    else
      puts "Please specify the type of event name which we want to trigger"
    end
  end
end
