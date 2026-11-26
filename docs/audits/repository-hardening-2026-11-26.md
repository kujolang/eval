# Eval repository hardening

Reviewed public `main` from `c1b263a10702c2fa8ab61ed507029a6bfec2e03d`. Verified implementation at `4b8e129d07bfdce28f027348fe5c674b94406eaf`. Eval checks deterministic command, HTTP, file, JSON, and snapshot evidence and publishes machine-readable results. The review covered the public command and check surfaces, policies, artifact and report contracts, snapshot I/O, release acceptance, fixture privacy, packaging and CI. The scoped changes address snapshot storage and the release gate. Eval depends on a pinned Kujo runtime and explicitly configured host capabilities.

The baseline passed the published CI and nine local fixture parity files. The canonical release gate failed locally while creating temporary files with BSD `mktemp`. The updated gate passed on the same host and pinned runtime without a tool substitution. [Baseline CI](https://github.com/kujolang/eval/actions/runs/39885469710)

| Priority | Finding | Fix and evidence |
| --- | --- | --- |
| P0 | The release verifier could accept files while the suite was still running, terminate the process, and ignore its final status. | Require a successful exit and verify the generated checksums before accepting a passing summary. A controlled fixture that emitted passing files and exited 17 was rejected. An altered generated receipt was also rejected. |
| P0 | Snapshot reads and updates followed unsafe file paths and overwrites were non-atomic. | Refuse symlink leaves and directories, read snapshot text beneath the configured root with a byte limit, and atomically replace regular snapshots. |
| P1 | Snapshot mismatch output could replay the whole input and concatenate the diff repeatedly. | Keep existing small positional diffs byte-for-byte, assemble output fragments, and cap diagnostic output at 64 KiB with a UTF-8-safe truncation marker. |
| P1 | Snapshot listing was unordered, accepted names merely containing `.snap`, and enumerated directory contents wholesale. | List sorted regular suffix-matched files through the bounded native directory page. Refuse a directory that exceeds the 10,000-candidate listing limit. |
| P1 | BSD temporary naming broke the release gate, and the workflow's Rust tool installation floated. | Use portable scratch templates, pin the toolchain action and Rust version to the existing Docker version, and grant CI read-only repository permissions. |

Seven alternating runs of a 3,000-line change on Intel macOS and the published Kujo 1.8.1 interpreter produced identical 60,027-byte diffs. Median compare time changed from 102.051 ms to 58.663 ms. Ranges were 97.160–106.963 ms and 57.123–60.070 ms. A 7,000-line change emitted 140,027 bytes before and 65,536 bytes after. Memory and token usage were unmeasured.

Public snapshot names, CLI flags, success result shapes, report schemas, and configured execution policies stay supported. File checks retain their host-authority constraints. Existing malformed snapshot-directory entries are omitted from listings. Oversized comparisons and unsafe paths return structured failure. No upstream dependency change was required.

All 16 local release gates passed on the exact published Kujo 1.8.1. The command, docs, artifact, parity and benchmark gates covered the new snapshot fixture. The explicit contract suite passed all 149 cases, and the standalone snapshot fixture passed in the VM and interpreter. The release gate's nonzero-exit and checksum-negative cases passed using local injected responses and temporary output.
