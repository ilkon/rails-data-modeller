# frozen_string_literal: true

class Publisher < ApplicationRecord
  has_many :vacancies, dependent: :destroy
  has_and_belongs_to_many :employers

  validates :name, presence: true, uniqueness: true, length: { in: 2..250 }

  strip_attributes :name

  scope :with_vacancies, -> { includes(:vacancies) }
  scope :with_employers, -> { includes(:employers) }
end
