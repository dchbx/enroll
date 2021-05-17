require 'rails_helper'

describe "MigrateFamily" do
  if true

    before :all do
      Dir[Rails.root.join('db', 'migrate', '*_create_family.rb')].each do |f|
        @path = f
        require f
      end
    end

    describe ".up", dbclean: :after_each do

      before :each do
        @migrations_paths = Rails.root.join("db/migrate")
        @test_version = @path.split("/").last.split("_").first
        Mongoid::Migrator.run(:up, @migrations_paths, @test_version.to_i)
        @migrated_family = Person.where(first_name: "Fatheroevwg", last_name: 'pqlvb').first.primary_family
        @migrated_application = FinancialAssistance::Application.all[0]
      end

      it "should match total migrated organizations" do
        expect(@migrated_application.family_id).to eq @migrated_family.id
      end
    end
  end
end
