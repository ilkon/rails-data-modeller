# frozen_string_literal: true

class UserRole < ApplicationRecord
  belongs_to :user, inverse_of: :user_role

  validates :user, uniqueness: true

  scope :with_user, -> { includes(:user) }
  scope :admins, -> { where(admin: true) }
end
