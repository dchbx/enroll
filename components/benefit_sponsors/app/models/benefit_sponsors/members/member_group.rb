# A collection of members, typically a family, who operate as a unit for purposes of benefit coverage
module BenefitSponsors
  class Members::MemberGroup
    include Enumerable

    attr_accessor :group_id, :group_enrollment
    attr_reader :members, :primary_member

    # group_enrollment (BenefitSponsors::Enrollments::GroupEnrollment)

    def initialize(collection = [], group_id: nil, group_enrollment: nil)
      self.members = collection
      @group_id         = group_id
      @group_enrollment = group_enrollment
    end

    def members=(member_list)
      @members = member_list
      @primary_member = @members.detect { |member| member.is_primary_member? }
    end

    def <<(new_member)
      is_duplicate_role?(new_member)
      new_members = members + [new_member]
      self.members = new_members
      self
    end

    def add_member(new_member)
      self << new_member
    end

    def [](member_id)
      @indexed_members[member_id]
    end

    def []=(index, member)
      is_duplicate_role?(new_member)
      @members[index] = member
      self.members = @members
    end

    def drop_member(member, &blk)
      members.delete(member)
    end

    def select!
      keep, discard = @members.partition { |m| yield m }
      self.members = keep
      discard_member_enrollments(discard)
    end

    def reject!
      discard, keep = @members.partition { |m| yield m }
      self.members = keep
      discard_member_enrollments(discard)
    end

    def each
      @members.each do |m|
        yield m
      end
    end

    def clone_for_coverage(new_product)
      self.class.new(
        members,
        {
          group_id: @group_id,
          group_enrollment: group_enrollment.clone_for_coverage(new_product)
        }
      )
    end

    def as_json(params = {})
      {
        members: members.as_json,
        group_id: group_id,
        group_enrollment: group_enrollment.as_json,
      }
    end

    private

    def discard_member_enrollments(removed_members)
      unless group_enrollment.nil?
        if removed_members.any?
          group_enrollment.remove_members_by_id!(removed_members.map(&:member_id))
        end
      end
    end

    def has_primary_member?
      @members.detect { |member| member.is_primary_member? }
    end

    def has_spouse_relationship?
      @members.detect { |member| member.is_spouse_relationship? }
    end

    def has_survivor_member?
      @members.detect { |member| member.is_survivor_member? }
    end

    def is_duplicate_role?(new_member)
      if new_member.is_primary_member? && has_primary_member?
        raise DuplicatePrimaryMemberError, "may have only one primary member"
      end

      if new_member.is_spouse_relationship? && has_spouse_relationship?
        raise MultipleSpouseRelationshipError, "primary member may have only one spouse relationship"
      end

      false
    end

  end

  class DuplicatePrimaryMemberError < StandardError; end
  class MultipleSpouseRelationshipError < StandardError; end
end
