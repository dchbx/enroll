require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'plan_benefit_template_parser')
require Rails.root.join('lib', 'object_builders', 'qhp_builder.rb')
require Rails.root.join('lib', 'object_builders', 'product_builder.rb')
require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'plan_rate_group_parser')
require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'plan_rate_group_list_parser')
require Rails.root.join('lib', 'object_builders', 'qhp_rate_builder.rb')

namespace :xml do
  desc "Import qhp plans from xml files"
  task :plans, [:file] => :environment do |task, args|
    files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls", EnrollRegistry[:enroll_app].setting(:state_abbreviation).item.downcase, "plans", "**", "*.xml"))
    # # files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls/plans/2017", "**", "*.xml"))
    # # files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls/plans/2017/Dental/IVL/Dominion/DominionIVLPlanBenefits7.20.16.xml"))
    # # files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls", "plans", "**", "Best Life IVL Plan Benefits Template.xml"))

    qhp_import_product_hash = files.inject(ProductBuilder.new({})) do |qhp_product_hash, file|
      puts file
      xml = Nokogiri::XML(File.open(file))
      product = Parser::PlanBenefitTemplateParser.parse(xml.root.canonicalize, :single => true)
      qhp_product_hash.add(product.to_hash)
      qhp_product_hash
    end

    qhp_import_product_hash.run

    qhp_import_hash = files.inject(QhpBuilder.new({})) do |qhp_hash, file|
      puts file
      xml = Nokogiri::XML(File.open(file))
      plan = Parser::PlanBenefitTemplateParser.parse(xml.root.canonicalize, :single => true)
      qhp_hash.add(plan.to_hash, file)
      qhp_hash
    end

    qhp_import_hash.run
  end
end


namespace :xml do
  desc "Import qhp rates from xml files"
  task :rates, [:action] => :environment do |task, args|
    files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls", EnrollRegistry[:enroll_app].setting(:state_abbreviation).item.downcase, "rates", "**", "*.xml"))
    # files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls/rates/2017/Health/United (Shop Only)", "UHIC", "**", "*.xml"))
    # files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls/rates/2017/Health/United (Shop Only)/UHIC/UHIC_SHOP_Rate_Tables_2017_v.1.xml"))
    rate_import_hash = files.inject(QhpRateBuilder.new()) do |rate_hash, file|
      action = args[:action] == "update" ? "update" : "new"
      puts file
      xml = Nokogiri::XML(File.open(file))
      year = file.split("/")[-3].to_i
      rates = if year < 2018
        Parser::PlanRateGroupParser.parse(xml.root.canonicalize, :single => true)
      else
        Parser::PlanRateGroupListParser.parse(xml.root.canonicalize, :single => true)
      end
      rate_hash.add(rates.to_hash, action, year)
      rate_hash
    end
    rate_import_hash.run

  end
end