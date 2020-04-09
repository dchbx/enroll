require "cucumber_booster_config/cucumber_file"

module CucumberBoosterConfig

  class Injection

    CUCUMBER_FILES = [
      "cucumber.yml",
      "config/cucumber.yml"
    ]

    def initialize(path, report_path, options = {})
      @path = path
      @report_path = report_path
      @dry_run = options.fetch(:dry_run, false)
    end

    def find_profile_files
      profile_files = []

      CUCUMBER_FILES.map { |file_name| cucumber_file_path(file_name) }.each do |file|
        if File.exist?(file)
          puts "Found Cucumber profile file: #{file}"
          profile_files << file
        end
      end

      profile_files
    end

    def run
      if no_profile_files?
        puts "No cucumber profile files found. Creating empty cucumber.yml file"
        FileUtils.touch("cucumber.yml")
      end

      find_profile_files.each do |path|
        CucumberFile.new(path, @dry_run).configure_for_autoparallelism(@report_path)
      end
    end

    private

    def no_profile_files?
      find_profile_files.empty?
    end

    def cucumber_file_path(file_name)
      File.join(@path, file_name)
    end
  end
end
