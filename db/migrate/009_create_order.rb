class CreateOrder < ActiveRecord::Migration[5.1]
  def change
    create_table :orders do |t|
      t.integer :order_snapshot_id, null: false, index: true
      t.integer :kind, null: false
      t.integer :price, null: false
      t.decimal :size, precision:10, scale: 8, null: false

      t.timestamps null: false
    end
  end
end
