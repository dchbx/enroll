require 'active_support/all'
require 'ui_helpers/engine'
require 'ui_helpers/helpers'
require 'ui_helpers/workflow_controller'

module UIHelpers
	ActiveSupport.on_load(:action_view) do
		include UIHelpers::Helpers
	end
end
