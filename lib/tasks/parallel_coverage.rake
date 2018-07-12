if ENV["COVERAGE"]
  namespace :parallel do
    desc "Remove coverage files before starting test run"
    task :remove_coverage_files => :environment do
      FileUtils.remove_dir(File.expand_path(File.join(Rails.root, "coverage")), true)
    end
  end

  Rake::Task["parallel:spec"].enhance(["parallel:remove_coverage_files"])
end
