module Queries
  class ProjectExpression < PipelineExpression
    def expression_step
      :project
    end

    def to_hash
      {
        "$project" => @expression
      }
    end
  end
end
