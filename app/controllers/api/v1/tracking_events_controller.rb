module Api
  module V1
    class TrackingEventsController < ApplicationController
      before_action :set_shipment

      def index
        render json: @shipment.tracking_events.order(occurred_at: :asc)
      end

      def create
        @tracking_event = @shipment.tracking_events.new(tracking_event_params)
        if @tracking_event.save
          WebhookDispatchService.call(@tracking_event)
          render json: @tracking_event, status: :created
        else
          render json: { errors: @tracking_event.errors }, status: :unprocessable_entity
        end
      end

      private

      def set_shipment
        @shipment = Shipment.find(params[:shipment_id])
      end

      def tracking_event_params
        params.require(:tracking_event).permit(:status, :location, :occurred_at, :notes)
      end
    end
  end
end
