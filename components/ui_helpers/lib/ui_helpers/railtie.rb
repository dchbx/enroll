require 'workflow_controller'

module UIHelpers
  class Railtie < Rails::Railtie
    initializer "ui_helper.action_controller" do
			ActiveSupport.on_load(:action_controller) do
				puts "Extending #{self} with YourGemsModuleName::Controller"
				# ActionController::Base gets a method that allows controllers to include the new behavior
			end
		end
	end
end
