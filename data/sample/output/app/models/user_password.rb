# frozen_string_literal: true

class UserPassword < ApplicationRecord
  belongs_to :user, inverse_of: :user_password

  validates :user, uniqueness: true
  validates :password, length: { in: Authonomy.password_length }, format: { with: Authonomy.password_regexp, message: 'should include a digit, uppercase and lowercase letter' }, unless: proc { |a| a.password.nil? }
  validates :reset_token, uniqueness: true

  strip_attributes :password

  scope :with_user, -> { includes(:user) }

  attr_accessor :password
end
