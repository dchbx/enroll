require_relative 'nav_helper'
require_relative 'tab_helper'
require_relative 'workflow_helper'

module UIHelpers
  module Helpers
    include UIHelpers::NavHelper
    include UIHelpers::TabHelper
    include UIHelpers::WorkflowHelper
	end
end
