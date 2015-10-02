require_relative "../helper"
require "ag/adapters/sequel_push"
require "ag/spec/adapter"

class AdaptersSequelPushTest < Ag::Test
  def setup
    Sequel.default_timezone = :utc
    @db = Sequel.sqlite

    @db.create_table :connections do
      primary_key :id
      String :consumer_id
      String :consumer_type
      String :producer_id
      String :producer_type
      Time :created_at
      index [:consumer_id, :consumer_type, :producer_id, :producer_type], unique: true
    end

    @db.create_table :events do
      primary_key :id
      String :producer_id
      String :producer_type
      String :object_id
      String :object_type
      String :verb
      Time :created_at
    end

    @db.create_table :timelines do
      primary_key :id
      String :consumer_id
      String :consumer_type
      String :event_id
      Time :created_at
    end
  end

  def adapter
    @adapter ||= Ag::Adapters::SequelPush.new(@db)
  end

  include Ag::Spec::Adapter
end
