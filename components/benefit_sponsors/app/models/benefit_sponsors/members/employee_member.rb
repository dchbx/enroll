module BenefitSponsors
  class Members::EmployeeMember < Members::Member

    field :date_of_hire,        type: Date 
    field :date_of_termination, type: Date

    after_initialize :set_self_relationship


    private

    def set_self_relationship
      kinship_to_primary_member = :self
    end


  end
end
