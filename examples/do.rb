require 'rx'

#  Using a function
source = Rx::Observable.range(0, 3)
  .do(
    lambda {|x|   puts 'Do Next:' + x.to_s },
    lambda {|err| puts 'Do Error:' + err.to_s },
    lambda {      puts 'Do Completed' }
  )

subscription = source.subscribe(
  lambda {|x|
    puts 'Next: ' + x.to_s
  },
  lambda {|err|
    puts 'Error: ' + err.to_s
  },
  lambda {
    puts 'Completed'
  })

# => Do Next: 0
# => Next: 0
# => Do Next: 1
# => Next: 1
# => Do Next: 2
# => Next: 2
# => Do Completed
# => Completed

#  Using an observer
observer = Rx::Observer.configure do |o|
  o.on_next { |x| puts 'Do Next: ' + x.to_s }
  o.on_error { |err| puts 'Do Error: ' + err.to_s }
  o.on_completed { puts 'Do Completed' }
end

source = Rx::Observable.range(0, 3)
    .do(observer)

subscription = source.subscribe(
  lambda {|x|
    puts 'Next: ' + x.to_s
  },
  lambda {|err|
    puts 'Error: ' + err.to_s
  },
  lambda {
    puts 'Completed'
  })

# => Do Next: 0
# => Next: 0
# => Do Next: 1
# => Next: 1
# => Do Next: 2
# => Next: 2
# => Do Completed
# => Completed
