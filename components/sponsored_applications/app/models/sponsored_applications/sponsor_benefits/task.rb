module SponsoredApplications
  class SponsorBenefits::Task

    attr_accessor :name, :parent

    def initialize(name)
      @name = name

      # Pointer to traverse upward from child tasks
      @parent = nil
    end


  end
end
