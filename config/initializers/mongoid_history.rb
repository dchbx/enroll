# frozen_string_literal: true

Mongoid::History.tracker_class_name = :history_tracker
Mongoid::History.current_user_method = :current_user

