module Api
  module V1
    class WebhookEndpointsController < ApplicationController
      before_action :set_webhook_endpoint, only: [:show, :update, :destroy]
      rescue_from ActiveRecord::InvalidForeignKey, with: :invalid_foreign_key

      def index
        @webhook_endpoints = WebhookEndpoint.order(created_at: :desc)
        render json: @webhook_endpoints
      end

      def show
        render json: @webhook_endpoint
      end

      def create
        @webhook_endpoint = WebhookEndpoint.new(webhook_endpoint_params)
        if @webhook_endpoint.save
          render json: @webhook_endpoint, status: :created
        else
          render json: { errors: @webhook_endpoint.errors }, status: :unprocessable_entity
        end
      end

      def update
        if @webhook_endpoint.update(webhook_endpoint_params)
          render json: @webhook_endpoint
        else
          render json: { errors: @webhook_endpoint.errors }, status: :unprocessable_entity
        end
      end

      def destroy
        @webhook_endpoint.destroy
        head :no_content
      end

      private

      def set_webhook_endpoint
        @webhook_endpoint = WebhookEndpoint.find(params[:id])
      end

      def webhook_endpoint_params
        params.require(:webhook_endpoint).permit(:url, :secret, :shipment_id, :active, status_filters: [])
      end

      def invalid_foreign_key
        render json: { errors: { shipment_id: ["is invalid"] } }, status: :unprocessable_entity
      end
    end
  end
end
