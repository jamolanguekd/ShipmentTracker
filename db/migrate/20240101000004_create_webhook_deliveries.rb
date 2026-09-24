class CreateWebhookDeliveries < ActiveRecord::Migration[6.1]
  def change
    create_table :webhook_deliveries do |t|
      t.references :webhook_endpoint, null: false, foreign_key: true
      t.references :tracking_event, null: false, foreign_key: true
      t.jsonb :payload, null: false
      t.integer :response_code
      t.text :response_body
      t.integer :status, null: false, default: 0
      t.integer :attempts, null: false, default: 0
      t.datetime :delivered_at
      t.datetime :next_retry_at

      t.timestamps
    end

    add_index :webhook_deliveries, [:webhook_endpoint_id, :created_at]
  end
end
