# frozen_string_literal: true

class User < ApplicationRecord
  enum status: { active: 0, blocked: 1 }

  has_many :user_emails, dependent: :destroy, inverse_of: :user
  has_one :user_password, dependent: :destroy, inverse_of: :user
  has_many :user_social_profiles, dependent: :destroy, inverse_of: :user
  has_one :user_role, dependent: :destroy, inverse_of: :user
  has_one :user_wallet, dependent: :destroy, inverse_of: :user
  has_one :user_address, dependent: :destroy, inverse_of: :user

  has_one_attached :logo, dependent: :purge_later

  validates :name, presence: true, length: { in: 3..120 }, allow_blank: true

  strip_attributes :name

  scope :with_user_emails, -> { includes(:user_emails) }
  scope :with_user_password, -> { includes(:user_password) }
  scope :with_user_social_profiles, -> { includes(:user_social_profiles) }
  scope :with_user_role, -> { includes(:user_role) }
  scope :with_user_wallet, -> { includes(:user_wallet) }
  scope :with_user_address, -> { includes(:user_address) }
end
