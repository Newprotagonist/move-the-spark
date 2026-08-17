# The `webpush` gem (<= 1.1.0) builds EC keys the pre-OpenSSL-3 way:
# `OpenSSL::PKey::EC.new(curve).generate_key` and mutating an existing key's
# `public_key=`/`private_key=`. The `openssl` gem shipped with Ruby 3.2+
# wraps OpenSSL 3.0's immutable EVP_PKEY objects, so all of that raises
# `OpenSSL::PKey::PKeyError: pkeys are immutable on OpenSSL 3.0`. This hits
# every push send (Webpush::Encryption ephemeral key) and any VAPID key
# built from stored keys (Webpush::VapidKey.from_keys/from_pem), so it isn't
# an edge case — it's unconditionally broken on this stack. Patch both spots
# to build keys the OpenSSL-3-safe way. Safe to remove once upstream ships a
# fix (tracked as a long-standing issue against zaru/webpush).
module Webpush
  module Openssl3Compat
    # Rebuilds an EC keypair from raw big numbers via DER encoding instead of
    # mutating a freshly-constructed key — the only way to attach existing
    # key material to an OpenSSL::PKey::EC on OpenSSL 3.
    def self.ec_key_from_raw(public_key_bn:, private_key_bn: nil)
      if private_key_bn
        private_key_octets = private_key_bn.to_s(2).rjust(32, "\x00".b)
        asn1 = OpenSSL::ASN1::Sequence.new([
          OpenSSL::ASN1::Integer.new(1),
          OpenSSL::ASN1::OctetString.new(private_key_octets),
          OpenSSL::ASN1::ASN1Data.new([ OpenSSL::ASN1::ObjectId.new("prime256v1") ], 0, :CONTEXT_SPECIFIC),
          OpenSSL::ASN1::ASN1Data.new([ OpenSSL::ASN1::BitString.new(public_key_bn.to_s(2)) ], 1, :CONTEXT_SPECIFIC)
        ])
        OpenSSL::PKey.read(asn1.to_der)
      else
        group = OpenSSL::PKey::EC::Group.new("prime256v1")
        point = OpenSSL::PKey::EC::Point.new(group, public_key_bn)
        der = OpenSSL::ASN1::Sequence.new([
          OpenSSL::ASN1::Sequence.new([
            OpenSSL::ASN1::ObjectId.new("id-ecPublicKey"),
            OpenSSL::ASN1::ObjectId.new("prime256v1")
          ]),
          OpenSSL::ASN1::BitString.new(point.to_octet_string(:uncompressed))
        ])
        OpenSSL::PKey.read(der.to_der)
      end
    end
  end

  class VapidKey
    def initialize
      @curve = OpenSSL::PKey::EC.generate("prime256v1")
    end

    def public_key=(key)
      @curve = Openssl3Compat.ec_key_from_raw(public_key_bn: to_big_num(key), private_key_bn: curve.private_key)
    end

    def private_key=(key)
      @curve = Openssl3Compat.ec_key_from_raw(public_key_bn: curve.public_key.to_bn, private_key_bn: to_big_num(key))
    end
  end

  module Encryption
    def encrypt(message, p256dh, auth)
      assert_arguments(message, p256dh, auth)

      group_name = "prime256v1"
      salt = Random.new.bytes(16)

      server = OpenSSL::PKey::EC.generate(group_name)
      server_public_key_bn = server.public_key.to_bn

      group = OpenSSL::PKey::EC::Group.new(group_name)
      client_public_key_bn = OpenSSL::BN.new(Webpush.decode64(p256dh), 2)
      client_public_key = OpenSSL::PKey::EC::Point.new(group, client_public_key_bn)

      shared_secret = server.dh_compute_key(client_public_key)

      client_auth_token = Webpush.decode64(auth)

      info = "WebPush: info\0" + client_public_key_bn.to_s(2) + server_public_key_bn.to_s(2)
      content_encryption_key_info = "Content-Encoding: aes128gcm\0"
      nonce_info = "Content-Encoding: nonce\0"

      prk = HKDF.new(shared_secret, salt: client_auth_token, algorithm: "SHA256", info: info).next_bytes(32)
      content_encryption_key = HKDF.new(prk, salt: salt, info: content_encryption_key_info).next_bytes(16)
      nonce = HKDF.new(prk, salt: salt, info: nonce_info).next_bytes(12)

      ciphertext = encrypt_payload(message, content_encryption_key, nonce)

      serverkey16bn = convert16bit(server_public_key_bn)
      rs = ciphertext.bytesize
      raise ArgumentError, "encrypted payload is too big" if rs > 4096

      aes128gcmheader = salt.to_s + [ rs ].pack("N*") + [ serverkey16bn.bytesize ].pack("C*") + serverkey16bn

      aes128gcmheader + ciphertext
    end
  end
end
