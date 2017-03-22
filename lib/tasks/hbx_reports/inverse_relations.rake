# Report: Rake task to find duplicate users account
# To Run Rake Task: RAILS_ENV=production bundle exec rake reports:primary_family_members:inverse_relations

require File.join(Rails.root, "app","reports","hbx_reports", "inverse_relations")

namespace :reports do
	namespace :primary_family_members do
		desc "List all relations that are inverse"
		InverseRelations.define_task :inverse_relations =>:environment
	end
end
