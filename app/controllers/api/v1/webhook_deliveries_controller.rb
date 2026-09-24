module Api
  module V1
    class WebhookDeliveriesController < ApplicationController
      before_action :set_webhook_endpoint

      def index
        render json: @webhook_endpoint.webhook_deliveries.order(created_at: :desc)
      end

      private

      def set_webhook_endpoint
        @webhook_endpoint = WebhookEndpoint.find(params[:webhook_endpoint_id])
      end
    end
  end
end
