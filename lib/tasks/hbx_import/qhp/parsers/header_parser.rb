require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'header_parser')

module Parser
  class HeaderParser
    include HappyMapper

    tag 'header'

    element :template_version, String, tag: 'templateVersion'
    element :issuer_id, String, tag: 'issuerId'
    element :state_postal_code, String, tag: 'statePostalCode'
    element :state_postal_name, String, tag: 'statePostalName'
    element :market_coverage, String, tag: 'marketCoverage'
    element :dental_plan_only_ind, String, tag: 'dentalPlanOnlyInd'
    element :tin, String, tag: 'tin'
    element :application_id, String, tag: 'applicationId'

    def to_hash
      {
        template_version: template_version.gsub(/\n/,'').strip,
        issuer_id: issuer_id.gsub(/\n/,'').strip,
        state_postal_code: state_postal_code.gsub(/\n/,'').strip,
        state_postal_name: state_postal_name.present? ? state_postal_name.gsub(/\n/,'').strip : "",
        market_coverage: market_coverage.gsub(/\n/,'').strip,
        dental_plan_only_ind: dental_plan_only_ind.gsub(/\n/,'').strip,
        tin: tin.present? ? tin.gsub(/\n/,'').gsub("-","").strip : "",
        application_id: application_id.present? ? application_id.gsub(/\n/,'').strip : ""
      }
    end
  end
end