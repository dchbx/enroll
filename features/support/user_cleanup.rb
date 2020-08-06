# frozen_string_literal: true

After do
  User.last.destroy if User.present?
end
