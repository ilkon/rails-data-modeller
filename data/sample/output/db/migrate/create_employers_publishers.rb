# frozen_string_literal: true

class CreateEmployersPublishers < ActiveRecord::Migration[6.0]
  def change
    table_name = 'employers_publishers'

    create_table table_name, id: false do |t|
      t.references :employer, index: false
      t.references :publisher, index: false
    end

    add_index table_name, :employer_id, name: "#{table_name}_employer"
    add_index table_name, :publisher_id, name: "#{table_name}_publisher"
  end
end
