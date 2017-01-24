FactoryGirl.define do
  factory :application_event_kind do
    
  trait :out_of_pocket_notice do 
  		event_name 'out_of_pocker_url_notifier'
  		title "Out of pocket notice"
  		resource_name "employer"
  		after(:create) do |instance|
  			create :notice_trigger ,:out_of_pocket_notice , application_event_kind: instance
  		end
	end
  end
end
