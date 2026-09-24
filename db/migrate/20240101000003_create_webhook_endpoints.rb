class CreateWebhookEndpoints < ActiveRecord::Migration[6.1]
  def change
    create_table :webhook_endpoints do |t|
      t.string :url, null: false
      t.string :secret, null: false
      t.references :shipment, null: true, foreign_key: true
      t.string :status_filters, array: true, default: []
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end
