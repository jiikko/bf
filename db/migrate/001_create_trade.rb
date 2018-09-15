class CreateTrade < ActiveRecord::Migration[5.1]
  def change
    create_table :trades do |t|
      t.integer :price, null: false
      t.timestamps null: false
      t.index :created_at
    end
  end
end
