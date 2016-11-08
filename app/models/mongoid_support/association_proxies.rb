module MongoidSupport
  module AssociationProxies
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def associated_with_one(attr_name, key_name, kls_name)
        kls = kls_name
        class_eval(<<-RUBYCODE)
          def #{attr_name}
            return @__proxy_value_for_#{attr_name} if @__proxy_value_for_#{attr_name}
            return nil if self.#{key_name}.blank?
            @__proxy_value_for_#{attr_name} ||= #{kls}.find(self.#{key_name})
          end

          def #{attr_name}=(val)
            @__proxy_value_for_#{attr_name} = val
            if val.nil?
              self.#{key_name} = nil
            else
              self.#{key_name} = val.id
            end
            val
          end

          def __association_reload_on_#{attr_name}
            @__proxy_value_for_#{attr_name} = nil
          end
        RUBYCODE
      end
    end
  end
end
