# frozen_string_literal: true

EnrollRegistry = ResourceRegistry::Registry.new

EnrollRegistry.configure do |config|
  config.name       = :enroll
  config.created_at = DateTime.now
  config.load_path  = Rails.root.join('system', 'config', 'templates', 'features').to_s
end