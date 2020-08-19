require 'rails_helper'
require 'rake'

describe 'load_core_applications' do

  before :all do
    load File.expand_path("#{Rails.root}/lib/tasks/load_core_applications.rake", __FILE__)
    Rake::Task.define_task(:environment)
    create_test_directory("#{Rails.root.to_s}/spec/test_data/seedfiles/fixtures_dump")
  end

  before :each do
    allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
  end

  let!(:primary_member) {FactoryGirl.create(:person, :with_consumer_role)}
  let!(:family) {FactoryGirl.create(:family, :with_primary_family_member, person: primary_member)}
  let!(:application) {FactoryGirl.create(:application, family: family)}
  let!(:applicant1) {FactoryGirl.create(:applicant, application: application, family_member_id: family.primary_applicant.id)}

  it 'should generate folder/files after running rake' do
    invoke_generate_faa_core
    glob_pattern = File.join(Rails.root,"spec", "test_data", "seedfiles/fixtures_dump", "application_*.yaml")
    folder = Dir.glob(glob_pattern)
    expect(folder.present?).to be true
  end

  it 'should load data from folder/files after running rake' do
    invoke_load_faa_core
    expect(family.applications.count).to be 1
  end

  after(:all) do
    FileUtils.rm_rf(Dir["#{Rails.root}//spec//test_data//seedfiles//fixtures_dump"])
  end
end

def invoke_generate_faa_core
  ENV["app_hbx_ids"]="faacore1:#{primary_member.hbx_id}"
  Rake::Task["fixture_dump:generate_applications"].reenable
  Rake::Task["fixture_dump:generate_applications"].invoke
end

def invoke_load_faa_core
  glob_pattern = File.join(Rails.root,"spec", "test_data", "seedfiles/fixtures_dump", "application_*.yaml")
  folder = Dir.glob(glob_pattern)

  if folder.present?
    Rake::Task["fixture_dump:load_applications"].reenable
    Rake::Task["fixture_dump:load_applications"].invoke(glob_pattern)
  end
end

def create_test_directory(path)
  if Dir.exists?(path)
    FileUtils.rm_rf(path)
  end
  Dir.mkdir path
end
