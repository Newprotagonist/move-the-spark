# A "push subscription" here means "this browser/device's subscription" —
# the client only ever creates or destroys its own, even though the table
# holds one row per device across however many the PWA is installed on.
class PushSubscriptionsController < ApplicationController
  def create
    subscription = PushSubscription.find_or_initialize_by(endpoint: params[:endpoint])
    subscription.assign_attributes(
      p256dh_key: params[:p256dh_key],
      auth_key: params[:auth_key],
      user_agent: request.user_agent
    )

    if subscription.save
      head :created
    else
      render json: { errors: subscription.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    PushSubscription.find_by(endpoint: params[:endpoint])&.destroy
    head :no_content
  end
end
