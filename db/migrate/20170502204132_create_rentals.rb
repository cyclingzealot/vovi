class CreateRentals < ActiveRecord::Migration
  def change
    create_table :rentals do |t|
      t.float :Price
      t.float :bedrooms
      t.integer :id
      t.float :longitude
      t.float :latitute
      t.float :pricePerRoom
      t.timestamp :lastConfirmed

      t.timestamps null: false
    end
  end
end
