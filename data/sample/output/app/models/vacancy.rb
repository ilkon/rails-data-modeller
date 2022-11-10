# frozen_string_literal: true

class Vacancy < ApplicationRecord
  include Partitionable

  REMOTENESS = %i[remote onsite].freeze
  INVOLVEMENT = %i[fulltime parttime].freeze

  belongs_to :publisher
  belongs_to :post
  belongs_to :employer, optional: true

  validates :published_at, presence: true
  validates :text, presence: true
  validates :date, presence: true
  validates :geo_latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :geo_longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }

  scope :with_publisher, -> { includes(:publisher) }
  scope :with_post, -> { includes(:post) }
  scope :with_employer, -> { includes(:employer) }

  serialize :skill_ids, ObjectToJsonbSerializer
  serialize :urls, ObjectToJsonbSerializer
  serialize :emails, ObjectToJsonbSerializer
end
