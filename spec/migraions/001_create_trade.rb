class CreateUsers < ActiveRecord::Migration
  def change
    create_table :trades do |t|
      t.integer :price
      t.integer :range_type, null: false
    end
  end
end
