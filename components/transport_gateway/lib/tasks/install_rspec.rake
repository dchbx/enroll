namespace :transport_gateway do
  desc "Install the specs into your project"
  task :install_rspec => :environment do
    spec_dir_path = File.join(Rails.root, "spec", "components")
    spec_path = File.join(Rails.root, "spec", "components", "transport_gateway_spec.rb")
    spec_template_file = File.join(File.dirname(__FILE__), "..", "..", "templates", "spec", "transport_gateway_spec.rb")
    FileUtils.mkdir_p(spec_dir_path)
    FileUtils.cp(spec_template_file, spec_path)
  end
end
