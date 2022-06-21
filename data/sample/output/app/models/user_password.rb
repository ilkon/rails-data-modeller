# frozen_string_literal: true

class UserPassword < ApplicationRecord
  belongs_to :user, inverse_of: :user_password

  validates :user, presence: true, uniqueness: true
  validates :password, length: { in: Attributor.password_length }, format: { with: Attributor.password_regexp, message: 'should include a digit, uppercase and lowercase letter' }, unless: proc { |a| a.password.nil? }
  validates :reset_token, uniqueness: true

  strip_attributes :password

  scope :with_user, -> { includes(:user).references(:users) }

  attr_accessor :password
end
