# Ag

WORK IN PROGRESS...

Experiments in describing feeds/timelines of events in code based on adapters so things can work at most levels of throughput.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "ag"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ag

## Usage

```ruby
require "ag"

adapter = Ag::Adapters::Memory.new
client = Ag::Client.new(adapter)
john = Ag::Object.new("User", "1")
steve = Ag::Object.new("User", "2")
presentation = Ag::Object.new("Presentation", "1")
event = Ag::Event.new({
  producer: steve,
  object: presentation,
  verb: "upload_presentation",
})

# connect john to steve
pp connect: client.connect(john, steve)

# is john connected to steve
pp connected?: client.connected?(john, steve)

# consumers of steve
pp consumers: client.consumers(steve)

# producers john is connected to
pp producers: client.producers(john)

# produce an event for steve
pp produce: client.produce(event)

# get the timeline of events for john based on the producers john follows
pp timeline: client.timeline(john)
```

## Contributing

1. Fork it ( https://github.com/jnunemaker/ag/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
