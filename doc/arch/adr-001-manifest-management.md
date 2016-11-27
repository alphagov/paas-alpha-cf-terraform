Context
=======
The alpha initially took the approach of starting with a vanilla set of cloud
foundry manifests, and merging new values into it using spiff. This became
difficult to reason about, and cf-release was forked because it was easier than
overriding necessary values using spiff. However, the confusing spiff hierarchy
remained.

Decision
========

We will create our own set of manifests based on those in cf-release. 

We will modify these as required.

We will use spruce to merge a series of files into the yml required by cloud
foundry

We will name the files with a numeric prefix and rely on shell globbing to
determine the merge order rather than listing the merge order in the
build-manifest script.

Status
======

Accepted

Consequences
============

We will need to define an upgrade path for our cloud foundry manifests - making
sure we pull in the required values from the new release manifests into ours.
