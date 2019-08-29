require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers','benefits_parser')

module Parser
  class BenefitsListParser
    include HappyMapper

    tag 'benefitsList'
    has_many :benefits, Parser::BenefitsParser, tag: "benefits"

    def to_hash
      {
        benefits: benefits.map(&:to_hash)
      }
    end
  end
end
