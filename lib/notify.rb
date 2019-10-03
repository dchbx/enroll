# frozen_string_literal: true

module Notify
  include Acapi::Notifiers

  def notify_change_event(obj, monitored_objs={})
    modal_name = obj.class.to_s.downcase
    monitored_objs.each do |name, attributes|
      attributes.each do |field|
        payload = payload(obj, field: field)
        if payload
          event_name = "#{modal_name}_#{name}_#{field}"
          notify("acapi.info.events.enrollment.#{event_name}", payload.to_xml)
        end
      end
    end
  rescue => e
    Rails.logger(e)
  end

  def payload(obj, field:)
    return nil unless obj.send(field)

    if obj.relations[field].present?
      # relation
      if obj.send(field).is_a?(Array)
        # embeds_many
        return nil if obj.send(field).blank?
        change_items = obj.send(field).select(&:changed?) 
        payload = case change_items.count
                  when 0
                    nil
                  when obj.send(field).select(&:new_record?).count
                    {"status" => "created", field => obj.send(field).select(&:new_record?)}
                  else
                    {"status" => "changed", field => change_items.map(&:changes)}
                  end
      else
        # embeds_one
        if obj.send(field).respond_to?(:new_record?)
          if obj.send(field).new_record?
            payload = {"status" => "created", field => obj.send(field)}
          else
            payload = {"status" => "changed", field => obj.send(field).changes}
          end
        else
          return nil
        end
      end
    else
      # field
      if obj.send("#{field}_changed?")
        payload = if obj.new_record?
                    {"status" => "created", field => obj.send("#{field}_change")}
                  else
                    {"status" => "changed", field => obj.send("#{field}_change")}
                  end
      else
        payload = nil
      end
    end
    payload
  rescue => e
    Rails.logger(e)
    return nil
  end
end
