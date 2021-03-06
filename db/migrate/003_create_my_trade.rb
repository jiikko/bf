class CreateMyTrade < ActiveRecord::Migration[5.1]
  def change
    create_table :my_trades do |t|
      t.integer :kind, null: false
      t.integer :status, null: false
      t.integer :price, null: false
      t.decimal :size, precision:10, scale: 8, null: false
      t.string :order_id
      t.string :order_acceptance_id
      t.text :error_trace
      t.text :params

      t.timestamps null: false
      t.index [:kind, :status, :updated_at]
    end
  end
end
