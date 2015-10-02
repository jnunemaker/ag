require_relative "../helper"
require "ag/adapters/sequel_pull_compact"
require "ag/spec/adapter"

class AdaptersSequelPullCompactTest < Ag::Test
  def setup
    Sequel.default_timezone = :utc
    @db = Sequel.sqlite

    @db.create_table :connections do
      primary_key :id
      String :consumer_id
      String :producer_id
      Time :created_at
      index [:consumer_id, :producer_id], unique: true
    end

    @db.create_table :events do
      primary_key :id
      String :producer_id
      String :object_id
      String :verb
      Time :created_at
    end
  end

  def adapter
    @adapter ||= Ag::Adapters::SequelPullCompact.new(@db)
  end

  include Ag::Spec::Adapter
end
