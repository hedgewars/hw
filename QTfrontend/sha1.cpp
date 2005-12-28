/*
 * Copyright (C) 1995, 1996, 1997, and 1998 WIDE Project.
 * All rights reserved.
 *
 * Copyright (c) 2005 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the project nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE PROJECT AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE PROJECT OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/*
 * FIPS pub 180-1: Secure Hash Algorithm (SHA-1)
 * based on: http://csrc.nist.gov/fips/fip180-1.txt
 * implemented by Jun-ichiro itojun Itoh <itojun@itojun.org>
 */

#include "sha1.h"

/* constant table */
static quint32 _K[] = { 0x5a827999, 0x6ed9eba1, 0x8f1bbcdc, 0xca62c1d6 };
#define	K(t)	_K[(t) / 20]

#define	F0(b, c, d)	(((b) & (c)) | ((~(b)) & (d)))
#define	F1(b, c, d)	(((b) ^ (c)) ^ (d))
#define	F2(b, c, d)	(((b) & (c)) | ((b) & (d)) | ((c) & (d)))
#define	F3(b, c, d)	(((b) ^ (c)) ^ (d))

#define	S(n, x)		(((x) << (n)) | ((x) >> (32 - n)))

#define	H(n)	(ctxt->h.b32[(n)])
#define	COUNT	(ctxt->count)
#define	BCOUNT	(ctxt->c.b64[0] / 8)
#define	W(n)	(ctxt->m.b32[(n)])

#define	PUTBYTE(x)	{ \
	ctxt->m.b8[(COUNT % 64)] = (x);		\
	COUNT++;				\
	COUNT %= 64;				\
	ctxt->c.b64[0] += 8;			\
	if (COUNT % 64 == 0)			\
		sha1_step(ctxt);		\
     }

#define	PUTPAD(x)	{ \
	ctxt->m.b8[(COUNT % 64)] = (x);		\
	COUNT++;				\
	COUNT %= 64;				\
	if (COUNT % 64 == 0)			\
		sha1_step(ctxt);		\
     }

static void sha1_step(struct sha1_ctxt *);

static void
sha1_step(struct sha1_ctxt *ctxt)
{
	quint32	a, b, c, d, e;
	size_t t, s;
	quint32	tmp;

	a = H(0); b = H(1); c = H(2); d = H(3); e = H(4);

	for (t = 0; t < 20; t++) {
		s = t & 0x0f;
		if (t >= 16) {
			W(s) = S(1, W((s+13) & 0x0f) ^ W((s+8) & 0x0f) ^ W((s+2) & 0x0f) ^ W(s));
		}
		tmp = S(5, a) + F0(b, c, d) + e + W(s) + K(t);
		e = d; d = c; c = S(30, b); b = a; a = tmp;
	}
	for (t = 20; t < 40; t++) {
		s = t & 0x0f;
		W(s) = S(1, W((s+13) & 0x0f) ^ W((s+8) & 0x0f) ^ W((s+2) & 0x0f) ^ W(s));
		tmp = S(5, a) + F1(b, c, d) + e + W(s) + K(t);
		e = d; d = c; c = S(30, b); b = a; a = tmp;
	}
	for (t = 40; t < 60; t++) {
		s = t & 0x0f;
		W(s) = S(1, W((s+13) & 0x0f) ^ W((s+8) & 0x0f) ^ W((s+2) & 0x0f) ^ W(s));
		tmp = S(5, a) + F2(b, c, d) + e + W(s) + K(t);
		e = d; d = c; c = S(30, b); b = a; a = tmp;
	}
	for (t = 60; t < 80; t++) {
		s = t & 0x0f;
		W(s) = S(1, W((s+13) & 0x0f) ^ W((s+8) & 0x0f) ^ W((s+2) & 0x0f) ^ W(s));
		tmp = S(5, a) + F3(b, c, d) + e + W(s) + K(t);
		e = d; d = c; c = S(30, b); b = a; a = tmp;
	}

	H(0) = H(0) + a;
	H(1) = H(1) + b;
	H(2) = H(2) + c;
	H(3) = H(3) + d;
	H(4) = H(4) + e;

	qMemSet(&ctxt->m.b8[0], 0, 64);
}

/*------------------------------------------------------------*/

void sha1_init(struct sha1_ctxt *ctxt)
{
	qMemSet(ctxt, 0, sizeof(struct sha1_ctxt));
	H(0) = 0x67452301;
	H(1) = 0xefcdab89;
	H(2) = 0x98badcfe;
	H(3) = 0x10325476;
	H(4) = 0xc3d2e1f0;
}

void sha1_pad(struct sha1_ctxt *ctxt)
{
	size_t padlen;		/*pad length in bytes*/
	size_t padstart;

	PUTPAD(0x80);

	padstart = COUNT % 64;
	padlen = 64 - padstart;
	if (padlen < 8) {
		qMemSet(&ctxt->m.b8[padstart], 0, padlen);
		COUNT += padlen;
		COUNT %= 64;
		sha1_step(ctxt);
		padstart = COUNT % 64;	/* should be 0 */
		padlen = 64 - padstart;	/* should be 64 */
	}
	qMemSet(&ctxt->m.b8[padstart], 0, padlen - 8);
	COUNT += (padlen - 8);
	COUNT %= 64;
	PUTPAD(ctxt->c.b8[0]); PUTPAD(ctxt->c.b8[1]);
	PUTPAD(ctxt->c.b8[2]); PUTPAD(ctxt->c.b8[3]);
	PUTPAD(ctxt->c.b8[4]); PUTPAD(ctxt->c.b8[5]);
	PUTPAD(ctxt->c.b8[6]); PUTPAD(ctxt->c.b8[7]);
}

void sha1_loop(struct sha1_ctxt *ctxt, const quint8 *input, size_t len)
{
	size_t gaplen;
	size_t gapstart;
	size_t off;
	size_t copysiz;

	off = 0;

	while (off < len) {
		gapstart = COUNT % 64;
		gaplen = 64 - gapstart;

		copysiz = (gaplen < len - off) ? gaplen : len - off;
		qMemCopy(&ctxt->m.b8[gapstart], &input[off], copysiz);
		COUNT += copysiz;
		COUNT %= 64;
		ctxt->c.b64[0] += copysiz * 8;
		if (COUNT % 64 == 0)
			sha1_step(ctxt);
		off += copysiz;
	}
}

void sha1_result(struct sha1_ctxt *ctxt, sha1_digest digest0)
{
	quint8 *digest;

	digest = (quint8 *)digest0;
	sha1_pad(ctxt);
	qMemCopy(digest, &ctxt->h.b8[0], 20);
}
