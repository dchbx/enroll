# frozen_string_literal: true

module PlanWorld
  def plan(*traits)
    attributes = traits.extract_options!
    @plan ||= FactoryBot.create :plan, *traits, attributes
  end
end

World(PlanWorld)

Given /a plan year(?:, )?(.*)(?:,) exists/ do |traits|
  plan *traits.sub(/, (and )?/, ',').gsub(' ', '_').split(',').map(&:to_sym), market: 'shop', coverage_kind: 'health', deductible: 4000
end
