# Original local experiment history

The completed research snapshot is published through the connected GitHub app
because the Windows Git CLI has no push credentials. Its publication commit is
a fast-forward from the existing experiment branch, with the same final files.
No main merge, scientific-result change, or forced branch update.

completed-loops-2026-10-07.bundle preserves the original local commits through
e38e9f42780dadd4544eb4ad93c36a754caa093d, including all exact candidate and runner
commit IDs cited in E001/E002/E003 records. Prerequisite: original remote E001
9d68f459019e9c5a20c5c513cf89aaf4a2cd2854, already in experiment branch history.
The snapshot contains the committed raw files directly; the bundle additionally
retains intermediate implementation history without rewriting the branch.

To make the original IDs available in a cloned repository without changing its
checkout, run from repository root:

```sh
git bundle verify optimization/history/completed-loops-2026-10-07.bundle
git fetch optimization/history/completed-loops-2026-10-07.bundle HEAD:refs/remotes/experiment-archive/completed-loops
```

Publication metadata differs from the original local commit metadata; original
research source identities remain recoverable through this bundle and retained
implementation patches. The final working application remains exact E001.
