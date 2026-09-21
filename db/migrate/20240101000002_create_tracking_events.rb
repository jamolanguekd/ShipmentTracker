class CreateTrackingEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :tracking_events do |t|
      t.references :shipment, null: false, foreign_key: true
      t.integer :status, null: false
      t.string :location
      t.datetime :occurred_at, null: false
      t.text :notes

      t.timestamps
    end
  end
end
