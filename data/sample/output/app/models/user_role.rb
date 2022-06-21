# frozen_string_literal: true

class UserRole < ApplicationRecord
  belongs_to :user, inverse_of: :user_role

  validates :user, presence: true, uniqueness: true

  scope :with_user, -> { includes(:user).references(:users) }
  scope :admins, -> { where(admin: true) }
end
