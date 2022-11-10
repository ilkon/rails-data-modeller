# frozen_string_literal: true

class UserWallet < ApplicationRecord
  belongs_to :user, inverse_of: :user_wallet

  validates :user, uniqueness: true
  validates :currency, presence: true
  validates :money, presence: true, format: { with: Authonomy.money_regexp, allow_blank: true }

  scope :with_user, -> { includes(:user) }

  def money
    @money ||= money_cents && money_cents / 100.0
  end

  def money=(val)
    self.money_cents = val.present? ? (val.to_f * 100.0).round : nil
    @money = val
  end
end
