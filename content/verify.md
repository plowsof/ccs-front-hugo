---
title: Check a donation address
url: /verify/
layout: verify
---

Every donation address on this site is one of the CCS wallet's subaddresses, taken from a
list made once, offline, from a view-only copy of the wallet, and signed. The site is checked
against the list each time it is made: an address that is not in it is never shown.

You can check it yourself, with nothing from this site but the files below:

1. Download [the list](/subaddresses.txt), [its signature](/subaddresses.txt.asc) and
   [the public key](/subaddresses.txt.key.asc).
2. Check the key's fingerprint against the one the CCS maintainers publish elsewhere (in the
   [design repository]({{< param designRepo >}}), in its README), then:

   ```
   gpg --import subaddresses.txt.key.asc
   gpg --verify subaddresses.txt.asc subaddresses.txt
   ```

3. Look for the address you are about to pay to: the one **your wallet shows** after you scan the
   QR code or paste the address, not the one on this page (a QR code can hold another address
   than the text beside it):

   ```
   grep -c " THE_ADDRESS$" subaddresses.txt
   ```

   `1` means it is the wallet's. `0` means do not send: tell the CCS maintainers.

The key's fingerprint: `{{fingerprint}}`

## Or ask the wallet itself

The wallet's address and view key are public ({{wallet_source}}), so you can also ask a copy of
the wallet whether an address is one of its own, without the list. A view key can't spend; it only shows
what the wallet received.

The wallet's address: `{{address}}`

Its view key: `{{viewkey}}`

Here too, use the address your wallet shows, after scanning or pasting. With `monero-wallet-rpc` from the Monero CLI ([getmonero.org](https://www.getmonero.org/downloads/),
check its hashes as the site explains), offline, in one terminal:

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

`"index":{"major":0,"minor":…}` means it is the wallet's. `Address doesn't belong to the wallet`
means do not send: tell the CCS maintainers. (The lookahead makes the copy look at its first
20,000 subaddresses; a fresh one only looks at 200.) Delete the `ccs-check` folder when done.
