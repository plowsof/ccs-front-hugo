---
title: Check a donation address
url: /verify/
layout: verify
---

Every donation address on this site is one of the CCS wallet's subaddresses, taken from a
list made once, offline, from a view-only copy of the wallet, and signed with a key made
only for that. The secret key was destroyed right after signing, so no other list can ever
carry that signature. The site is checked against the list each time it is made: an address
that is not in it is never shown.

You can check it yourself, with nothing from this site but the files below:

1. Download [the list](/subaddresses.txt), [its signature](/subaddresses.txt.asc) and
   [the public key](/assets/subaddresses-key.asc).
2. Check the key's fingerprint against the one the CCS maintainers publish elsewhere (in the
   [front end's repository]({{< param frontendRepo >}}) and in its README), then:

   ```
   gpg --import subaddresses-key.asc
   gpg --verify subaddresses.txt.asc subaddresses.txt
   ```

3. Look for the address you are about to pay to:

   ```
   grep -c " THE_ADDRESS$" subaddresses.txt
   ```

   `1` means it is the wallet's. `0` means do not send: tell the CCS maintainers.

The key's fingerprint: `{{< param "subaddresses.key" >}}`
