module Queries
  class UnwindExpression < PipelineExpression
    def expression_step
      :unwind
    end

    def to_hash
      {
        "$unwind" => @expression
      }
    end
  end
end
