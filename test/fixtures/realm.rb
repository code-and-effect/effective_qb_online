puts "Running effective_qb_online test seeds"

# This has to match a real Quickbooks Online realm
realm = Effective::QbRealm.first_or_initialize

realm.update!(
  realm_id: ENV.fetch('QB_REALM_ID'),
  access_token: ENV.fetch('QB_ACCESS_TOKEN'),
  refresh_token: ENV.fetch('QB_REFRESH_TOKEN'),
  access_token_expires_at: (Time.zone.now + 1.hour),
  refresh_token_expires_at: (Time.zone.now + 100.days)
)
