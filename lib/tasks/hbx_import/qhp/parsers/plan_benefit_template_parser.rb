require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'package_list_parser')

module Parser
  class PlanBenefitTemplateParser
    include HappyMapper

    tag 'planBenefitTemplateVO'

    has_one :packages_list, Parser::PackageListParser, :tag => "packagesList"

    def to_hash
      {
        packages_list: packages_list.to_hash
      }
    end
  end
end
