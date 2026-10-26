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

[How to make a view-only wallet](https://www.getmonero.org/resources/user-guides/view_only.html).
Then ask it with `monero-wallet-rpc`
([reference](https://docs.getmonero.org/interacting/monero-wallet-rpc-reference/)):
`set_subaddress_lookahead` with `minor_idx` 20000 (the donation addresses are past the first 200),
then `get_address_index` with the address. An index: it is the CCS wallet's. "Address doesn't
belong to the wallet": do not send, and tell the CCS maintainers.
