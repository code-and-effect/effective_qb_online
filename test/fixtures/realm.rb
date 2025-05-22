puts "Running effective_qb_online test seeds"

# This has to match a real QuickBooks Online realm
realm = Effective::QbRealm.first_or_initialize

realm.update!(
  realm_id: ENV.fetch('QB_REALM_ID', 'realm'),
  access_token: ENV.fetch('QB_ACCESS_TOKEN', 'token'),
  refresh_token: ENV.fetch('QB_REFRESH_TOKEN', 'refresh'),
  deposit_to_account_id: ENV.fetch('QB_DEPOSIT_TO_ACCOUNT', 'account'),
  payment_method_id: ENV.fetch('QB_PAYMENT_METHOD', 'method'),
  access_token_expires_at: (Time.zone.now + 1.hour),
  refresh_token_expires_at: (Time.zone.now + 100.days)
)
