# One row per browser/device the PWA has been granted push permission on.
# Pushes fan out to every row; a subscription that the push service reports
# as gone (404/410 — e.g. the app was uninstalled) prunes itself.
class PushSubscription < ApplicationRecord
  validates :endpoint, presence: true, uniqueness: true
  validates :p256dh_key, presence: true
  validates :auth_key, presence: true

  # Sends the same notification to every subscribed device.
  def self.broadcast(title:, body:, path: "/")
    payload = { title: title, options: { body: body, data: { path: path } } }.to_json
    find_each { |subscription| subscription.deliver(payload) }
  end

  def deliver(payload)
    Webpush.payload_send(
      message: payload,
      endpoint: endpoint,
      p256dh: p256dh_key,
      auth: auth_key,
      vapid: vapid_options
    )
  rescue Webpush::ExpiredSubscription, Webpush::InvalidSubscription
    destroy
  end

  private

  def vapid_options
    {
      subject: Rails.application.credentials.dig(:vapid, :subject),
      public_key: Rails.application.credentials.dig(:vapid, :public_key),
      private_key: Rails.application.credentials.dig(:vapid, :private_key)
    }
  end
end
