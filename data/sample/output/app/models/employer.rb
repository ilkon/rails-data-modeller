# frozen_string_literal: true

class Employer < ApplicationRecord
  has_many :vacancies, dependent: :destroy
  has_and_belongs_to_many :publishers

  validates :name, presence: true, uniqueness: true, length: { in: 2..250 }
  validates :url, format: { with: Attributor.url_regexp, allow_blank: true }

  strip_attributes :name, :url

  scope :with_vacancies, -> { includes(:vacancies).references(:vacancies) }
  scope :with_publishers, -> { includes(:publishers).references(:publishers) }
end
