class CreateVolume < ActiveRecord::Migration[5.1]
  def change
    create_table :volumes do |t|
      t.integer :volume, null: false
      t.integer :best_bid, null: false
      t.integer :best_ask, null: false
      t.float :best_bid_size, null: false
      t.float :total_bid_depth, null: false
      t.float :total_ask_depth, null: false

      t.timestamps null: false
      t.index :created_at
    end
  end
end
