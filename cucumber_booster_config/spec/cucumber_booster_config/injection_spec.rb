require "spec_helper"

describe CucumberBoosterConfig::Injection do

  context "when the project has no cucumber configuration" do
    before do
      expect(File.exists?("cucumber.yml")).to be(false)

      CucumberBoosterConfig::Injection.new(".", "/tmp/report_path.json").run
    end

    it "creates a new cucumber.yml file" do
      expect(File.exists?("cucumber.yml")).to be(true)
    end

    it "inserts semaphoreci profile" do
      lines = File.open("cucumber.yml", "r") { |f| f.readlines }

      expect(lines[0].chomp).to eql("semaphoreci: --format json --out=/tmp/report_path.json")
    end

    it "inserts a default profile definition" do
      lines = File.open("cucumber.yml", "r") { |f| f.readlines }

      expect(lines[1].chomp).to eql(CucumberBoosterConfig::CucumberFile::DEFAULT_PROFILE)
    end

    after do
      FileUtils.rm("cucumber.yml")
    end
  end

  context "when the blank cucumber.yml is in root" do

    before do
      FileUtils.touch("cucumber.yml")
      CucumberBoosterConfig::Injection.new(".", "/tmp/report_path.json").run
    end

    it "inserts semaphoreci profile" do
      lines = File.open("cucumber.yml", "r") { |f| f.readlines }

      expect(lines[0].chomp).to eql("semaphoreci: --format json --out=/tmp/report_path.json")
    end

    it "inserts a default profile definition" do
      lines = File.open("cucumber.yml", "r") { |f| f.readlines }

      expect(lines[1].chomp).to eql(CucumberBoosterConfig::CucumberFile::DEFAULT_PROFILE)
    end

    after do
      FileUtils.rm("cucumber.yml")
    end
  end

  context "when config/cucumber.yml is found" do

    context "with a default profile" do

      before do
        FileUtils.mkdir_p("config")
        File.open("config/cucumber.yml", "w") do |f|
          f.puts "default: <%= common %>"
        end
      end

      it "inserts semaphoreci profile and appends it to default profile" do
        CucumberBoosterConfig::Injection.new(".", "/tmp/report_path.json").run

        lines = []
        File.open("config/cucumber.yml", "r") { |f| lines = f.readlines }

        expect(lines.size).to eql(2)
        expect(lines[0].chomp).to eql("default: <%= common %> --profile semaphoreci")
        expect(lines[1].chomp).to eql("semaphoreci: --format json --out=/tmp/report_path.json")
      end

      it "doesn't create semaphoreci profile if it is already created" do
        2.times { CucumberBoosterConfig::Injection.new(".", "/tmp/report_path.json").run }

        lines = File.readlines("config/cucumber.yml")
        semaphoreci_profiles = lines.select do |line|
          line.chomp == "semaphoreci: --format json --out=/tmp/report_path.json"
        end

        expect(semaphoreci_profiles.count).to eq(1)
      end

      it "doesn't append semaphoreci profile to default if it is already appended" do
        2.times { CucumberBoosterConfig::Injection.new(".", "/tmp/report_path.json").run }

        default_profile = File.readlines("config/cucumber.yml").first
        semaphoreci_appended_profiles = default_profile.scan("--profile semaphoreci")
        expect(semaphoreci_appended_profiles.count).to eq(1)
      end
    end

    context "default profile is missing" do

      before do
        FileUtils.mkdir_p("config")
        File.open("config/cucumber.yml", "w") do |f|
          f.puts "todd: --format progress --tags @wip CUC=on"
        end
      end

      it "inserts a new line that defines the default profile" do
        CucumberBoosterConfig::Injection.new(".", "/tmp/report_path.json").run

        lines = []
        File.open("config/cucumber.yml", "r") { |f| lines = f.readlines }

        expect(lines.size).to eql(3)
        expect(lines[0].chomp).to eql("todd: --format progress --tags @wip CUC=on")
        expect(lines[1].chomp).to eql("semaphoreci: --format json --out=/tmp/report_path.json")
        expect(lines[2].chomp).to eql("default: --format pretty --profile semaphoreci features")
      end
    end

    after do
      FileUtils.rm_rf("config")
    end
  end
end
