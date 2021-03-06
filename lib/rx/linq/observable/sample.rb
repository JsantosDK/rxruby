module Rx
  module Observable
    # Return the latest item from this observable when another observable
    # emits an item.
    def sample(intervalOrSampler, scheduler = DefaultScheduler.instance, &recipe)
      sampler = if intervalOrSampler.is_a? Numeric
        Observable.interval(intervalOrSampler, scheduler)
      else
        intervalOrSampler
      end

      AnonymousObservable.new do |observer|
        latest = nil
        has_value = false
        gate = Mutex.new
        sampler_observer = Observer.configure do |o|
          o.on_next do |sampler_data|
            next unless has_value
            to_emit = nil
            gate.synchronize do
              to_emit = latest
              latest = nil
            end
            begin
              to_emit = recipe.call(to_emit, sampler_data) unless recipe.nil?
              observer.on_next to_emit
            rescue => err
              observer.on_error err
            end
          end
          o.on_error(&observer.method(:on_error))
          o.on_completed(&observer.method(:on_completed))
        end

        sampler_subscription = sampler.subscribe(sampler_observer)

        self_observer = Rx::Observer.configure do |me|
          me.on_next do |value|
            gate.synchronize do
              has_value = true
              latest = value
            end
          end
          me.on_error(&observer.method(:on_error))
          me.on_completed(&observer.method(:on_completed))
        end

        self_subscription = subscribe self_observer

        CompositeSubscription.new [sampler_subscription, self_subscription]
      end
    end
  end
end
