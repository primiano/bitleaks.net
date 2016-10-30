Title: A (almost) Perfectly Forward Secret OpenSSL one-liner
Tags: security
Date: 2014-10-11
Icon: icon.png
Abstract: A quick one-liner which might come handy in paranoid occasions. It shows how to initiate a very simple and cryptographically robust connection between two hosts, which has forward secrecy properties, with a one line invocation of OpenSSL.

This is a simple one-liner which leverages `openssl s_client` and `openssl s_server` (essentially a TLS-version of netcat) to establish a point-to-point channel with Perfect Forward Secrecy (PFS) properties.   
I find it useful for occasions like bringing up quickly a paranoid PFS conversation without having to trust fancy programs (trusting OpenSSL itself is becoming a pretty big effort lately).


A quick overview of PFS
-----------------------
The Internet has [plenty of articles](https://www.google.com/search?&q=perfect%20forward%20secrecy) which explain in great details, much better than how I could do here, the theory and the technical implications of PFS.

In a nutshell, PFS is based on ephemeral keys which guarantee isolation between sessions. If the key for a session is compromised, it cannot be used to decode past or future sessions.
This is the opposite, for instance, of what happens with PGP-encrypted mails. If the private key gets compromised, all the past mails encrypted using that key are compromised (can be decrypted).

In practice, PFS is achieved today using online key exchange like system like [Diffie-Hellman](https://en.wikipedia.org/wiki/Diffie%E2%80%93Hellman_key_exchange) (and variants). DH is an extremely elegant and clever key exchange method which allows two endpoints to agree *in the open* (i.e. over an insecure channel) a random key, in a way that makes it *cryptographically hard* for an eavesdropper in the middle to obtain the key, even if it it managed to tap both sides of the key exchange.

Obligatory note
---------------
Forward secrecy itself does not guarantee any protection against man-in-the-middle (MITM) attacks (see notes about adding extra PKI auth below).

Furthermore, you are warned that the examples shown in this article lack some other desirable security properties: even when protecting against MITM, an eavesdropper can still be able to see that a connection between two hosts is ongoing and infer some interesting properties by inspecting the volume and the rate of the encrypted streams.

In other words, this article might give you a false sense of security. If you don't feel having enough background these topics, you should probably stop at this point.

Command line one-liners
-----------------------
### Server side
    openssl s_server -accept 12345 -nocert -cipher aNULL

### Other endpoint (client)
    openssl s_client -connect hostname:12345 -cipher aNULL

aNULL is a collection of OpenSSL cipher-suites which don't perform any authentication, but do perform encryption using the ephemeral keys. In practice, this means using anonymous DH / ECDH (its elliptical variant).

### Adding some MITM robustness:
The aforementioned commands can be given MITM robustness using a similar approach to what web servers do using RSA-based PKI.
This will guarantee authentication of one party (the server side), which breaks half of the MITM chain (i.e. the server endpoint has still no way to ascertain the identity of the client, but not the other way round).

ECDHE-RSA-AES256-SHA is one (and nowadays pretty popular) cipher of the OpenSSL suite which enables this. It consists in an ephemeral Elliptic Diffie-Hellman key exchange, which agrees an ephemeral AES-256 key, followed by a RSA PKI authentication.

Assuming that you have a valid certificate and key-pair and a way to establish the server certificate validity (see note below), the authenticated variant of the previous one-liner becomes:

### Server side
    openssl s_server -accept 12345 -cipher ECDHE-RSA-AES256-SHA -key key.file -cert cert.file

### Other endpoint (client)
    openssl s_client -connect hostname:12345 -cipher ECDHE-RSA-AES256-SHA

Note: you must be able to verify the validity of the server certificate in order for this to make sense. In other words: just because the server is presenting a certificate, doesn't give itself the guarantee about its authenticity. It could be just a self-signed certificate.
The way you address this problem is either having a server certificate which is signed by a trusted CA (you can use the -CAfile and -verify arguments of openssl to enforce CA verification), or having acquired the server certificate by other means and checking its fingerprint.
