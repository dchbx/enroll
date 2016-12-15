class Queries::PipelineExpression
  attr_reader :expression

  def initialize(expr = {})
    @expression = expr
  end

  def to_hash
    @expression
  end

  def to_pipeline
    [to_hash]
  end

  def >>(other_expression)
    ::Queries::Pipeline.new(to_pipeline + other_expression.to_pipeline)
  end

  def expression_step
    "raw"
  end

  def join_expression(other_exp)
    exp_val = other_exp.respond_to?(:expression) ? other_exp.expression : other_exp
    self.class.new(@expression.merge(exp_val.to_hash))
  end

  def +(other_expression)
    exp_step = other_expression.respond_to?(:expression_step) ? other_expression.expression_step : "raw"
    raise "Expression chain mismatch:\nTried to join #{expression_step} to #{exp_step}\n" if (exp_step != expression_step)
    join_expression(other_expression)
  end
end
