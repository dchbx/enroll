module Queries
  class GroupExpression
    def initialize(group_by_statement, other_properties)
      @id_grouping = group_by_statement
      @other_props = other_properties
    end

    def expression_step
      :group
    end

    def to_hash
      {
        "$group" => {
          "_id" => @id_grouping.to_hash
        }.merge(@other_props.to_hash)
      }
    end

    def to_pipeline
      [to_hash]
    end
  end
end
