require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'plan_parser')

module Parser
  class PlanListParser
    include HappyMapper

    tag 'plansList'

    has_many :plans, Parser::PlanParser, tag: "plans"

    def to_hash
      {
        plans: plans.map(&:to_hash)
      }
    end
  end
end
