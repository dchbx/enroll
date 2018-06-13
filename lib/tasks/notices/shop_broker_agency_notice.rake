# This rake task used to send employer notices it expects FEIN and event_name as arguments.
# RAILS_ENV=production bundle exec rake notice:shop_broker_agency_notice["464398642 043023600 821356381 263082892 261813097 384325339",broker_agency_hired_confirmation]
namespace :notice do
  desc "Generate shop broker agency hired notices"
  task :shop_broker_agency_notice, [:feins, :event_name] => :environment do |task, args|

    feins = args[:feins].split(' ').uniq
    @event_name = args[:event_name].to_s

    if feins.present?
      feins.each do | fein |
        employer_profile = EmployerProfile.find_by_fein(fein)
        if employer_profile.present? && @event_name.present?
          puts "Generating notice for broker agency #{employer_profile.active_broker_agency_account.legal_name}"
          ShopNoticesNotifierJob.perform_later(employer_profile.id.to_s, @event_name)
          puts "Notice triggered Successfully"
        else
          Rails.logger.error "shop_broker_agency_notice: invalid arguments."
        end
      end
    end
  end
end