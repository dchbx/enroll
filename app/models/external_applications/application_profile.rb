# frozen_string_literal: true

module ExternalApplications
  class ApplicationProfile
    attr_reader :name, :url, :policy_class

    def initialize(app_name, setting_set)
      @name = app_name
      @url = setting_set.url
      @policy_class = self.class.const_get(setting_set.pundit_policy)
    end

    def is_authorized_for?(current_user)
      @policy_class.new(current_user, nil).visit?
    end

    def self.find_by_application_name(app_name)
      external_apps = load_external_applications
      external_apps.detect do |ea|
        ea.name == app_name.strip
      end
    end

    def self.load_external_applications
      external_apps = Settings.external_applications
      external_apps.keys.map do |k|
        self.new(k.to_s, external_apps.send(k.to_sym))
      end
    end
  end
end