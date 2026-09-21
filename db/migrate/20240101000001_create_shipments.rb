class CreateShipments < ActiveRecord::Migration[6.1]
  def change
    create_table :shipments do |t|
      t.string :reference_number, null: false
      t.string :origin, null: false
      t.string :destination, null: false
      t.string :carrier
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :shipments, :reference_number, unique: true
  end
end
