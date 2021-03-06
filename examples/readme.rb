require_relative "setup"
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
