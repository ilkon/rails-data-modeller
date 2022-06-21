# frozen_string_literal: true

class CreateUserWallets < ActiveRecord::Migration[6.0]
  def change
    table_name = 'user_wallets'

    create_table table_name do |t|
      t.references :user, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.string :currency, null: false
      t.bigint :money_cents, null: false, default: 0.0

      t.timestamps
    end

    add_index table_name, :user_id, unique: true, name: "#{table_name}_user_id"
    add_index table_name, :currency, name: "#{table_name}_currency"
  end
end
