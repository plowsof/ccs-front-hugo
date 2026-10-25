---
title: Check a donation address
url: /verify/
layout: verify
---

Every donation address on this site is one of the CCS wallet's subaddresses, taken from a
list made once, offline, from a view-only copy of the wallet, and signed. The site is checked
against the list each time it is made: an address that is not in it is never shown.

**Check it with something that doesn't come from this site.** Whoever took over this site could
change the donation addresses, and with them the list, its signature, its key and everything
written on this page, all to match each other. So the one thing this check trusts, the key (or
the wallet's address and view key, below), must come from somewhere else.

1. **Get the key from outside this site.** The CCS maintainers publish it, and its fingerprint,
   in the design repository on GitHub, `github.com/plowsof/ccs-front-hugo`: the key in its
   `keys/` folder, the fingerprint in its README. Type that address yourself, or find the
   repository from getmonero.org or the Monero community, rather than following a link from this
   page. Better still, ask someone you trust for the fingerprint.
2. Download [the list](/subaddresses.txt) and [its signature](/subaddresses.txt.asc) from here:
   the signature is what makes them trustworthy, not where they come from. Then, with the key you
   got in step 1:

   ```
   gpg --import <the key from step 1>
   gpg --fingerprint                          # the fingerprint you got in step 1
   gpg --verify subaddresses.txt.asc subaddresses.txt
   ```

   `Good signature` from that key: the list is the one the maintainers signed.

3. Look for the address you are about to pay to: the one **your wallet shows** after you scan the
   QR code or paste the address, not the one on this page (a QR code can hold another address
   than the text beside it):

   ```
   grep -c " THE_ADDRESS$" subaddresses.txt
   ```

   `1` means it is the wallet's. `0` means do not send: tell the CCS maintainers.

What this site says the key's fingerprint is: `{{fingerprint}}`. Only a cross-check: if it
differs from the one you got elsewhere, do not send, and tell the CCS maintainers.

## Or ask the wallet itself

The wallet's address and view key are public ({{wallet_source}}), so you can also ask a copy of
the wallet whether an address is one of its own, without the list or the key. A view key can't
spend; it only shows what the wallet received. **Take them from where they were published**
(monero-project/meta issue #935 on GitHub, found yourself), not from this page: a copy of another
wallet would say yes to that wallet's addresses.

What this site says they are, to compare:

The wallet's address: `{{address}}`

Its view key: `{{viewkey}}`

Here too, use the address your wallet shows, after scanning or pasting. With `monero-wallet-rpc` from the Monero CLI ([getmonero.org](https://www.getmonero.org/downloads/),
check its hashes as the site explains), offline, in one terminal:

```
monero-wallet-rpc{{network}} --offline --wallet-dir ccs-check --rpc-bind-port 18088 --disable-rpc-login
```

and in another, with the address and view key from where they were published:

```
rpc() { curl -s http://127.0.0.1:18088/json_rpc -d "{\"jsonrpc\":\"2.0\",\"id\":0,\"method\":\"$1\",\"params\":$2}"; }
rpc generate_from_keys '{"filename":"ccs","address":"{{address}}","viewkey":"{{viewkey}}","password":""}'
rpc set_subaddress_lookahead '{"password":"","major_idx":1,"minor_idx":20000}'
rpc get_address_index '{"address":"THE_ADDRESS"}'
```

`"index":{"major":0,"minor":…}` means it is the wallet's. `Address doesn't belong to the wallet`
means do not send: tell the CCS maintainers. (The lookahead makes the copy look at its first
20,000 subaddresses; a fresh one only looks at 200.) Delete the `ccs-check` folder when done.
