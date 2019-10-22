require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'cost_share_variance_parser')

module Parser
  class PlanDeductibleListParser
    include HappyMapper

    tag 'planDeductibleList'

    has_many :plan_deductible_attributes, Parser::DeductibleParser, tag: "planDeductible"

    def to_hash
      {
        plan_deductible_attributes: plan_deductible_attributes.map(&:to_hash)
      }
    end
  end
end
