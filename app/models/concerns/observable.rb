# frozen_string_literal: true

module Concerns
  module Observable
    extend ActiveSupport::Concern

    included do
      attr_reader :observer_peers

      delegate :add_observer, to: :class
      register_observers

      after_initialize do |_instance|
        @observer_peers = {}
        register_observers
      end

      def register_observers
        @observer_peers = add_observer(Observers::NoticeObserver.new, update_method_name.to_sym, @observer_peers)
      end

      def update_method_name
        "#{self.class.model_name.param_key}_update"
      end

      def delete_observers
        @observer_peers.clear if defined? @observer_peers
      end

      def notify_observers(*arg)
        if defined? @observer_peers
          @observer_peers.each do |k, v|
            k.send v, *arg
          end
        end
      end
    end

    class_methods do

      def add_observer(observer, func = :update, observers)
        raise NoMethodError, "observer does not respond to '#{func}'" unless observer.respond_to? func

        observers[observer] = func if observers.none?{|k, _v| k.is_a?(observer.class)}
        observers
      end

      def register_observers
        @@observer_peers ||= {}
        @@observer_peers[self.to_s] ||= []

        add_observer_peer = lambda do |observer_instance|
          matched_peer = @@observer_peers[self.to_s].detect{|peer| peer.any?{|k, _v| k.is_a?(observer_instance.class)}}
          @@observer_peers[self.to_s] << add_observer(observer_instance, update_method_name.to_sym, {}) if matched_peer.blank?
        end

        add_observer_peer.call(Observers::NoticeObserver.new)
      end

      def update_method_name
        "#{self.model_name.param_key}_date_change"
      end

      def notify_observers(*arg)
        if defined? @@observer_peers
          @@observer_peers[self.to_s].each do |peer|
            peer.each do |k, v|
              k.send v, *arg
            end
          end
        end
      end
    end
  end
end
