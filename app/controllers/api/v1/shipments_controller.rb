module Api
  module V1
    class ShipmentsController < ApplicationController
      before_action :set_shipment, only: [:show, :update, :destroy]

      def index
        @shipments = Shipment.order(created_at: :desc)
        render json: @shipments
      end

      def show
        render json: @shipment
      end

      def create
        @shipment = Shipment.new(shipment_params)
        if @shipment.save
          render json: @shipment, status: :created
        else
          render json: { errors: @shipment.errors }, status: :unprocessable_entity
        end
      end

      def update
        if @shipment.update(shipment_params)
          render json: @shipment
        else
          render json: { errors: @shipment.errors }, status: :unprocessable_entity
        end
      end

      def destroy
        @shipment.destroy
        head :no_content
      end

      private

      def set_shipment
        @shipment = Shipment.find(params[:id])
      end

      def shipment_params
        params.require(:shipment).permit(:reference_number, :origin, :destination, :carrier, :status)
      end
    end
  end
end
