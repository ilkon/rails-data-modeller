# frozen_string_literal: true

class UserAddress < ApplicationRecord
  belongs_to :user, inverse_of: :user_address

  validates :user, uniqueness: true
  validates :address_line, presence: true
  validates :city, presence: true
  validates :postal_code, presence: true
  validates :country, presence: true
  validates :phone, presence: true, length: { in: Authonomy.phone_length }, format: { with: Authonomy.phone_regexp }

  strip_attributes :address_line, :address_line2, :city, :postal_code, :country, :phone

  scope :with_user, -> { includes(:user) }
end
