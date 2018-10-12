class CreateOrderSnapshot < ActiveRecord::Migration[5.1]
  def change
    create_table :order_snapshots do |t|
      t.text :memo
      t.boolean :restored, default: false, null: false
      t.string :product_code, null: false

      t.timestamps null: false
    end
  end
end
