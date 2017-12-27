# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx/core/observer'
require 'rx/subscriptions/single_assignment_subscription'

module Rx

  class AutoDetachObserver < Rx::ObserverBase

    def on_next_core(value) 
      no_error = false
      begin
        @observer.on_next(value)
        no_error = true
      ensure
        unsubscribe unless no_error
      end
    end

    def on_error_core(error)
      begin
        @observer.on_error(error)
      ensure
        unsubscribe
      end
    end

    def on_completed_core
      begin
        @observer.on_completed
      ensure
        unsubscribe
      end
    end

    def initialize(observer)
      @observer = observer
      @m = SingleAssignmentSubscription.new

      config = ObserverConfiguration.new
      config.on_next(&method(:on_next_core))
      config.on_error(&method(:on_error_core))
      config.on_completed(&method(:on_completed_core))

      super(config)
    end

    def subscription=(new_subscription)
      @m.subscription = new_subscription
    end

    def unsubscribe
      super
      @m.unsubscribe
    end
  end
  
  class AwaitableObserver < AutoDetachObserver
    def initialize(observer)
      super
      @completed = false
      @condition = ConditionVariable.new
    end

    def subscription=(new_subscription)
      blocker = Subscription.create do
        @completed = true
        @condition.signal
      end
      super CompositeSubscription.new([new_subscription, blocker])
    end

    def await(timeout)
      raise RuntimeError.new 'Cannot await before subscription' unless subscription
      gate = Mutex.new
      deadline = Time.now + timeout
      until Time.now >= deadline || @completed
        gate.synchronize do
          @condition.wait(gate, deadline - Time.now) unless @completed
        end
      end
      @completed
    end
  end
end

