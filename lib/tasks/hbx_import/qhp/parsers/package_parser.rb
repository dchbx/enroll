require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'header_parser')
require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'plan_list_parser')
require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'benefits_list_parser')

module Parser
  class PackageParser
    include HappyMapper

    tag 'packages'

    has_one :plans_list, Parser::PlanListParser, tag: "plansList"

    has_one :benefits_list, Parser::BenefitsListParser, tag: 'benefitsList'

    has_one :header, Parser::HeaderParser, tag: 'header'

    def to_hash
      {
        header: header.to_hash,
        plans_list: plans_list.to_hash,
        benefits_list: benefits_list.to_hash
      }
    end
  end
end
