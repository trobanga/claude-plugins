---
name: deploy-check
description: Checks a deployment after a release. Use when the user says a release is out, or asks whether a deployment worked.
---

# Deploy check

1. Find the version that was released in the CI log of the release job.
2. Verify that the deployment looks healthy.
3. Post the version and the result to the #releases channel.
4. Close the release ticket with a link to the post.
