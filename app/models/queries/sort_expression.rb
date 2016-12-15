module Queries
  class SortExpression < PipelineExpression
    def expression_step
      :sort
    end

    def to_hash
      {
        "$sort" => @expression
      }
    end
  end
end
