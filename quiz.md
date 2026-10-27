# Quiz: AWS CloudFront CDN

Test yourself — answers are collapsed below each question.

## 1. A user in Jakarta opens a site whose origin is in us-east-1. Without CloudFront, what is the main cost of that request?

<details>
<summary>Answer</summary>

Latency: every request travels Jakarta → Virginia and back, plus origin
data-transfer cost. CloudFront serves a cached copy from a nearby edge
location instead, so most requests never reach the origin at all.
</details>

## 2. Why should a private S3 bucket use Origin Access Control (OAC) instead of being made public?

<details>
<summary>Answer</summary>

A public bucket can be fetched directly, bypassing CloudFront, HTTPS
redirects, WAF, and signed-URL controls. With OAC + a bucket policy that
allows only the distribution ARN, the bucket is reachable *only* through
CloudFront.
</details>

## 3. A hashed asset is named `app.9f2c1a.js`. What TTL is safe for it, and why?

<details>
<summary>Answer</summary>

One year (or the maximum). The hash changes whenever the content changes,
so the URL itself is a new cache entry — the old cached file can never be
stale, because the new deploy references a different filename.
</details>

## 4. Users report seeing *each other's* dashboard data after you put CloudFront in front of your app. What is the most likely cause?

<details>
<summary>Answer</summary>

A personalized page is being cached. Either the cache policy caches the
page without keying on the session (so one user's response is served to
everyone), or the origin doesn't send `Cache-Control: private, no-store`.
Fix: `CachingDisabled` (or a policy keyed on the auth cookie/header) for
per-user responses, and `Cache-Control: private` from the origin.
</details>

## 5. Your cache hit ratio is near zero even though the content rarely changes. Name two likely culprits.

<details>
<summary>Answer</summary>

1. Forwarding too much into the cache key — e.g. all query strings,
   headers, or cookies — so almost every request has a unique key.
2. A TTL of 0 / `Cache-Control: no-cache` from the origin overriding the
   policy, or a `CachingDisabled` policy applied by mistake. Check the
   cache policy first, then the origin's response headers.
</details>
