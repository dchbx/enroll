# initializers/share_helpers_path_with_engine.rb
SponsoredBenefits::Engine.class_eval do
  paths["app/helpers"] << File.join(File.dirname(__FILE__), '../..', 'app/helpers')
end