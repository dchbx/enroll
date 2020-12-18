# frozen_string_literal: true

module Entities
  module People
    module Roles
      # Account entity that holds roles information.
      # We use this entity to build forms
      class Account < Dry::Struct
        transform_keys(&:to_sym)

        attribute :roles,  Types::Array.of(Entities::People::Roles::Role)

        def active_roles
          roles.select{|role| role.status == :active}
        end

        def inactive_roles
          roles.select{|role| role.status == :inactive}
        end

        def pending_roles
          roles.select{|role| role.status == :pending}
        end

        def resident_roles
          roles.select{|role| role.kind == "resident"}
        end

        def admin_roles
          roles.select{|role| role.kind.match(/hbx/)}
        end
      end
    end
  end
end