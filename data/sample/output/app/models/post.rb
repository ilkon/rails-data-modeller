# frozen_string_literal: true

class Post < ApplicationRecord
  include Partitionable

  belongs_to :publisher

  validates :publisher_key, presence: true, uniqueness: { scope: :publisher_id }
  validates :published_at, presence: true
  validates :last_fetched_at, presence: true
  validates :date, presence: true

  scope :with_publisher, -> { includes(:publisher) }

  class << self
    def create_indexes(schema, table)
      connection.execute("CREATE UNIQUE INDEX #{table}_publisher_id_publisher_key ON #{schema}.#{table} (publisher_id, publisher_key)")
    end
  end
end
