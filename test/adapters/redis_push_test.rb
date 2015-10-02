require_relative "../helper"
require "ag/adapters/redis_push"
require "ag/spec/adapter"

class AdaptersRedisPushTest < Ag::Test
  def setup
    @redis = Redis.new(:port => ENV.fetch("GH_REDIS_PORT", 6379).to_i)
    @redis.flushdb
  end

  def adapter
    @adapter ||= Ag::Adapters::RedisPush.new(@redis)
  end

  include Ag::Spec::Adapter
end
