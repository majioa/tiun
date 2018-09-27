class CreateTestModels < ActiveRecord::Migration[4.2]
   def change
      create_table :test_models do |t|
         t.string :str
         t.integer :int
         t.boolean :bool
         t.text :txt
         t.date :date
         t.timestamp :time

         t.timestamps null: false ;end;end;end
