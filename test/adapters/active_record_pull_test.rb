require_relative "../helper"
require "ag/adapters/active_record_pull"
require "ag/spec/adapter"

ActiveRecord::Base.establish_connection(adapter: "sqlite3",
                                        database: ":memory:")

ActiveRecord::Base.connection.create_table :ag_connections do |t|
  t.string :consumer_id, null: false
  t.string :consumer_type, null: false
  t.string :producer_id, null: false
  t.string :producer_type, null: false
  t.timestamps
  t.index [:consumer_id, :consumer_type, :producer_id, :producer_type], unique: true, name: :consumer_to_producer
end

ActiveRecord::Base.connection.create_table :ag_events do |t|
  t.string :producer_id, null: false
  t.string :producer_type, null: false
  t.string :object_id, null: false
  t.string :object_type, null: false
  t.string :verb, null: false
  t.datetime :created_at, null: false
end

class AdaptersActiveRecordPullTest < Ag::Test
  def setup
    Ag::Adapters::ActiveRecordPull::Connection.delete_all
    Ag::Adapters::ActiveRecordPull::Event.delete_all
  end

  def adapter
    @adapter ||= Ag::Adapters::ActiveRecordPull.new
  end

  include Ag::Spec::Adapter
end
