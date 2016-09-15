class CensusDependent < CensusMember

  EMPLOYEE_RELATIONSHIP_KINDS = %W[spouse domestic_partner child_under_26  child_26_and_over disabled_child_26_and_over nephew_or_niece grandchild]

  embedded_in :census_employee

  validates :employee_relationship,
            presence: true,
            allow_blank: false,
            allow_nil:   false,
            inclusion: {
              in: EMPLOYEE_RELATIONSHIP_KINDS,
              message: "'%{value}' is not a valid employee relationship"
            }
            
end