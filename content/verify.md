---
title: Check a donation address
url: /verify/
layout: verify
---

Check the address **your wallet shows** (after scanning or pasting) in a view-only copy of the CCS
wallet, made from its public address and view key ({{wallet_source}}; take them from there, not
from this page, and open it yourself rather than only through this page's link: a web server that
lies could change the link too):

- Address: `{{address}}`
- View key: `{{viewkey}}`

[Make a view-only wallet](https://www.getmonero.org/resources/user-guides/view_only.html) from them
(it needs no sync and no node), then open it in `monero-wallet-rpc` v0.18.4.1 or later
([reference](https://docs.getmonero.org/interacting/monero-wallet-rpc-reference/)), offline:

```
monero-wallet-rpc --wallet-file <the view-only wallet> --password <its password> --offline \
    --rpc-bind-port 18090 --disable-rpc-login
```

and, in another terminal, ask it about the address. First a bigger subaddress lookahead: a new
wallet knows only its first 200, and the donation addresses are among the first 15,000.

```
curl -s http://127.0.0.1:18090/json_rpc -d '{"jsonrpc":"2.0","id":"0","method":"set_subaddress_lookahead","params":{"password":"<its password>","major_idx":1,"minor_idx":20000}}'
curl -s http://127.0.0.1:18090/json_rpc -d '{"jsonrpc":"2.0","id":"0","method":"get_address_index","params":{"address":"<the address>"}}'
```

An index (`"index": {"major": 0, "minor": …}`): it is the CCS wallet's. "Address doesn't belong to
the wallet" or "Invalid address" (after the lookahead): do not send, and tell the CCS maintainers.
