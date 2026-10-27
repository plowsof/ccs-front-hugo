---
title: Check a donation address
url: /verify/
layout: verify
---

Check the address **your wallet shows** (after scanning or pasting) in a view-only copy of the CCS
wallet, made from its public address and view key ({{wallet_source}}; take them from there, not
from this page):

- Address: `{{address}}`
- View key: `{{viewkey}}`

[How to make a view-only wallet](https://www.getmonero.org/resources/user-guides/view_only.html)
(it needn't sync). Then ask it with `monero-wallet-rpc` v0.18.4.1 or later
([reference](https://docs.getmonero.org/interacting/monero-wallet-rpc-reference/)): first a
bigger subaddress lookahead (the donation addresses are past the first 200), then the address:

```
set_subaddress_lookahead  {"password": "<your wallet's password>", "major_idx": 1, "minor_idx": 20000}
get_address_index         {"address": "<the address>"}
```

An index: it is the CCS wallet's. "Address doesn't belong to the wallet": do not send, and tell
the CCS maintainers.
