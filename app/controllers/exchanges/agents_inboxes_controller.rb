# frozen_string_literal: true

module Exchanges
  class AgentsInboxesController < InboxesController
    def find_inbox_provider
      @inbox_provider = current_user.person
      @inbox_provider_name = "Agent"
    end

    def destroy
      @sent_box = true
      super
    end

    def show
      @sent_box = true
      super
    end

  end
end
