module BenefitSponsors
  class Members::MemberRoster
    include Enumerable

    attr_reader :member_groups

    def initialize
      @member_groups = []
      @rate_schedule_date = nil
    end

    def each(&block)
      @member_groups.each { |member_group| block.call(member_group) }
    end

    def add_member_group(new_member_group)
      @member_groups << new_member_group
    end

    def drop_member_group(member_group)
      @member_groups.delete(member_group)
    end

    def <<(new_member_group)
      add_member_group(new_member_group)
    end

    def [](index)
      # @member_groups[index]
      @member_groups = index.each { |new_member_group| add_member(new_member_group) }
      
    end

    def []=(index, new_member_group)
      @member_groups[index] = new_member_group
    end


  end
end
