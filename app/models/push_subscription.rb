# One row per browser/device the PWA has been granted push permission on.
# Pushes fan out to every row; a subscription that the push service reports
# as gone (404/410 — e.g. the app was uninstalled) prunes itself.
class PushSubscription < ApplicationRecord
  validates :endpoint, presence: true, uniqueness: true
  validates :p256dh_key, presence: true
  validates :auth_key, presence: true

  # Sends the same notification to every subscribed device.
  #
  # icon: the app logo shown in the notification body. badge: a small
  # monochrome silhouette (transparent background, opaque shape — Android
  # tints it and shows it in the status bar) rather than reusing the
  # full-color icon, which Android would otherwise flatten into a solid
  # colored blob. Both versioned the same way as the static <link> icons
  # (see ApplicationHelper::ICON_VERSION) — these URLs get the same
  # 1-year cache-control as any other public/ file, so an icon update
  # needs the same cache-busting or already-delivered notifications (and
  # the OS's own icon cache) keep showing the old one.
  def self.broadcast(title:, body:, path: "/")
    payload = {
      title: title,
      options: {
        body: body,
        icon: "/icon-192.png?v=#{ApplicationHelper::ICON_VERSION}",
        badge: "/badge-96.png?v=#{ApplicationHelper::ICON_VERSION}",
        data: { path: path }
      }
    }.to_json
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
