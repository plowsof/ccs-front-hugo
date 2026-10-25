---
title: Check a donation address
url: /verify/
layout: verify
---

Every donation address here is one of the CCS wallet's subaddresses, from a list made offline and
signed. Check it with a key that **doesn't come from this site**: whoever took over the site could
change the addresses, the list, its signature and this page together.

1. Get the key from the design repository, `github.com/plowsof/ccs-front-hugo` (in `keys/`, its
   fingerprint in the README). Type the address yourself rather than following a link from here,
   or ask someone you trust for the fingerprint.
2. Download [the list](/subaddresses.txt) and [its signature](/subaddresses.txt.asc), and check
   them with that key:

   ```
   gpg --import <the key from step 1>
   gpg --verify subaddresses.txt.asc subaddresses.txt
   ```

3. Look for the address **your wallet shows** after scanning or pasting (a QR code can hold
   another address than the text beside it):

   ```
   grep -c " THE_ADDRESS$" subaddresses.txt
   ```

   `1`: it is the wallet's. `0`: do not send, tell the CCS maintainers.

This site says the fingerprint is `{{fingerprint}}`: if it differs from the one you got, do not send.

## Or ask the wallet itself

The wallet's address and view key are public ({{wallet_source}}): take them from there, found
yourself, not from this page. A copy of the wallet made from them, offline, says whether an address
is its own; a view key can't spend. This site says they are:

The wallet's address: `{{address}}`

Its view key: `{{viewkey}}`

With `monero-wallet-rpc` from the Monero CLI ([getmonero.org](https://www.getmonero.org/downloads/),
hashes checked), in one terminal:

```
monero-wallet-rpc{{network}} --offline --wallet-dir ccs-check --rpc-bind-port 18088 --disable-rpc-login
```

and in another:

```
rpc() { curl -s http://127.0.0.1:18088/json_rpc -d "{\"jsonrpc\":\"2.0\",\"id\":0,\"method\":\"$1\",\"params\":$2}"; }
rpc generate_from_keys '{"filename":"ccs","address":"{{address}}","viewkey":"{{viewkey}}","password":""}'
rpc set_subaddress_lookahead '{"password":"","major_idx":1,"minor_idx":20000}'
rpc get_address_index '{"address":"THE_ADDRESS"}'
```

`"index":{"major":0,"minor":…}`: it is the wallet's. `Address doesn't belong to the wallet`: do
not send, tell the CCS maintainers. Delete `ccs-check` when done.
