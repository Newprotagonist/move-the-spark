import { Controller } from "@hotwired/stimulus"

// "Enable notifications" toggle button. Subscribes this browser to Web
// Push (VAPID) and posts the subscription to the server, or tears it down.
export default class extends Controller {
  static targets = ["button"]

  async connect() {
    if (!this.supported) {
      this.buttonTarget.disabled = true
      this.buttonTarget.textContent = "Notifications non supportées par ce navigateur"
      return
    }

    const registration = await navigator.serviceWorker.ready
    const existing = await registration.pushManager.getSubscription()
    this.render(!!existing)
  }

  get supported() {
    return "serviceWorker" in navigator && "PushManager" in window
  }

  async toggle() {
    const registration = await navigator.serviceWorker.ready
    const existing = await registration.pushManager.getSubscription()

    if (existing) {
      await this.unsubscribe(existing)
      this.render(false)
      return
    }

    const permission = await Notification.requestPermission()
    if (permission !== "granted") return

    const subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: this.urlBase64ToUint8Array(this.vapidPublicKey)
    })
    await this.postSubscription(subscription)
    this.render(true)
  }

  async unsubscribe(subscription) {
    await this.deleteSubscription(subscription)
    await subscription.unsubscribe()
  }

  async postSubscription(subscription) {
    const json = subscription.toJSON()
    await fetch("/push_subscription", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": this.csrfToken },
      body: JSON.stringify({
        endpoint: json.endpoint,
        p256dh_key: json.keys.p256dh,
        auth_key: json.keys.auth
      })
    })
  }

  async deleteSubscription(subscription) {
    await fetch("/push_subscription", {
      method: "DELETE",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": this.csrfToken },
      body: JSON.stringify({ endpoint: subscription.endpoint })
    })
  }

  render(enabled) {
    this.buttonTarget.textContent = enabled ? "Désactiver les notifications" : "Activer les notifications"
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }

  get vapidPublicKey() {
    return document.querySelector('meta[name="vapid-public-key"]')?.content
  }

  urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - (base64String.length % 4)) % 4)
    const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/")
    const rawData = atob(base64)
    return Uint8Array.from([ ...rawData ].map((char) => char.charCodeAt(0)))
  }
}
