module Sortable
  extend ActiveSupport::Concern

  included do
    # Sort all models newest to oldest using created_at
    # default_scope   ->{ order(:"created_at".desc) }

    scope :order_recent,  ->{ order(:"created_at".desc).limit(100) }

    scope :order_created_asc,   ->{ order(:"created_at".asc) }
    scope :order_created_desc,  ->{ order(:"created_at".desc) }
    scope :order_updated_asc,   ->{ order(:"updated_at".asc) }
    scope :order_updated_desc,  ->{ order(:"updated_at".desc) }
    scope :order_name_asc,      ->{ order(:"last_name".asc, :"first_name".asc) }
    scope :order_name_desc,     ->{ order(:"last_name".desc, :"first_name".desc) }
  end

  module ClassMethods
    def order_by(method)
      case method.to_s
      when 'recent' then order_recent
      when 'created_asc' then order_created_asc
      when 'created_desc' then order_created_desc
      when 'updated_asc' then order_updated_asc
      when 'updated_desc' then order_updated_desc
      when 'name_asc' then order_name_asc
      when 'name_desc' then order_name_desc
      else
        all
      end
    end
  end
end
