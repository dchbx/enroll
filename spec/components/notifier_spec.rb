require 'rails_helper'

if ("Notifier::Engine".constantize rescue nil)
  Dir[Rails.root.join("components/notifier/spec/**/*_spec.rb")].each do |f|
    require f
  end
end
