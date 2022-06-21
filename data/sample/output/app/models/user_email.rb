# frozen_string_literal: true

class UserEmail < ApplicationRecord
  belongs_to :user, inverse_of: :user_emails

  validates :user, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: Attributor.email_regexp }
  validates :confirm_token, uniqueness: true

  before_validation { email.downcase! if email.present? }
  strip_attributes :email

  scope :with_user, -> { includes(:user).references(:users) }
end
