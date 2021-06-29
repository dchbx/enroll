# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")
class UpdateQleTooltip < MongoidMigrationTask

  def migrate
    qle_title = ENV['title']
    qles = QualifyingLifeEventKind.where(title: qle_title).first
    if qles.present?
      tooltip_text = ENV['text']
      qles.update_attributes(tool_tip: tooltip_text)
      puts "updated qle tooltip successfully." unless Rails.env.test?
    else
      puts "Qle tooltip not found." unless Rails.env.test?
    end
  end
end
