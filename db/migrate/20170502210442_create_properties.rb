class CreateProperties < ActiveRecord::Migration
  def change
    create_table :properties do |t|
      t.text :address
      t.text :url
      t.float :longitude
      t.float :latitude
      t.float :listingPrice
      t.float :bedrooms
      t.float :bathrooms
      t.integer :builtIn
      t.boolean :garage
      t.timestamp :lastConfirmed

      t.timestamps null: false
    end
  end
end
