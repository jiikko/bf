class CreateMyTrade < ActiveRecord::Migration[5.1]
  def change
    create_table :my_trades do |t|
      t.integer :kind, null: false
      t.integer :status, null: false
      t.integer :price, null: false
      t.float :size, null: false
      t.string :order_id
      t.text :error_trace

      t.timestamps null: false
    end
  end
end

