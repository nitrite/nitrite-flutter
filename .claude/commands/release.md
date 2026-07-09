---
description: Bump version, update CHANGELOGs, and publish a new nitrite-flutter release to pub.dev
argument-hint: "[major|minor|patch] (optional - overrides the auto-detected bump type)"
---

You are cutting a release of nitrite-flutter. This publishes real, permanent package versions to
pub.dev across 5 packages. **pub.dev does not allow unpublishing or reusing a version number.**
Follow every step; do not skip the confirmation gates. Read this whole file before doing
anything — the tag-creation mechanics in Step 6 are unintuitive and getting them wrong silently
breaks the publish with no error message.

## How this repo's release pipeline actually works (verified, do not re-derive from scratch)

- **5 packages release in lockstep to one shared version**: `packages/nitrite` (the real code),
  `packages/nitrite_generator`, `packages/nitrite_hive_adapter`, `packages/nitrite_spatial`,
  `packages/nitrite_support`. `examples/nitrite_demo` is **excluded** — it's an example app with
  its own independent, much slower version cadence, and the melos `publish` script itself ignores
  it (`melos exec --ignore="*demo*"`). Never touch its version as part of a release.
- Each package has its own `.github/workflows/<package>-release.yml` (5 separate workflow files:
  `nitrite-release.yml`, `nitrite_generator-release.yml`, `nitrite_hive_adapter-release.yml`,
  `nitrite_spatial-release.yml`, `nitrite_support-release.yml`). Each triggers on push of a tag
  matching `'<package>-[0-9]+.[0-9]+.[0-9]+*'` — this is **5 independent tags per release**, not
  one shared tag, e.g. `nitrite-2.0.3`, `nitrite_generator-2.0.3`, etc. Each workflow runs
  `melos run generate` (build_runner codegen), `melos run lint:all`, then
  `flutter pub publish --force` for just that one package. Takes ~4 minutes per package; all 5
  run in parallel once all 5 tags are pushed.
- **Critical, non-obvious pitfall (hit and root-caused in this repo):** the tag **must be
  lightweight**. Pre-creating the tag yourself with `git tag -a <tag> -m "..."` (annotated) and
  then `git push origin <tag>` produces a tag that **silently never triggers the workflow** — no
  error, no run, nothing (confirmed: 5/5 annotated tags pushed this way produced zero workflow
  runs, while every historical lightweight tag triggered correctly). The reliable method is to
  let `gh release create <tag> --target <sha>` mint the tag itself (verified: this always produces
  a lightweight tag and reliably triggers the workflow). **Therefore: for this repo, always create
  the release via `gh release create <tag> --target <sha> ...` directly — do not run `git tag` /
  `git push origin <tag>` yourself first.** If you ever need to pre-create a tag manually for some
  other reason, use `git tag <name>` with no `-a`/`-m` flag.
- GitHub Release naming convention: title is `"<package> vX.Y.Z"` (e.g. `"nitrite v2.0.3"`), tag
  is `<package>-X.Y.Z`. The **last** release created in a batch automatically gets GitHub's
  "Latest" badge (no explicit flag needed) — historically that's `nitrite_support`, so create the
  5 releases in this fixed order: `nitrite`, `nitrite_generator`, `nitrite_hive_adapter`,
  `nitrite_spatial`, `nitrite_support`.
- `pubspec.lock` is gitignored — do not worry about committing it.

## Step 1 — Preflight

1. `git status --short` — must be clean. If not, stop and tell the user what's uncommitted.
2. `git fetch origin --quiet && git log --oneline main..origin/main` — must be empty. If not,
   stop; do not silently rebase over unknown remote commits.
3. Confirm you are on `main`.

## Step 2 — Determine the version bump

1. Find the last release tag for the anchor package: `git tag -l 'nitrite-[0-9]*' | sort -V |
   tail -1` (strip the `nitrite-` prefix to get the last version, e.g. `nitrite-2.0.3` → `2.0.3`).
2. `git log <lastNitriteTag>..HEAD --oneline` to see everything since the last release.
3. Classify using Conventional Commits semantics:
   - **major**: an explicit `BREAKING CHANGE:` footer, a `!` after the type, a removed/renamed
     public API, or a minimum-SDK bump (this repo has precedent: 2.0.0 was
     `**BREAKING CHANGE**: Upgraded minimum Dart SDK to 3.5.0`).
   - **minor**: new capability without breaking compatibility (`feat:`, new index type, new
     public API added).
   - **patch**: everything else — bug fixes / maintenance only (`fix:`, `chore:`, `docs:`,
     `refactor:`, `test:`, dependency bumps).
   - Take the highest applicable level across all commits since the last tag.
4. If `$ARGUMENTS` explicitly names `major`, `minor`, or `patch`, that overrides your
   classification — but still show your own analysis first so the user can see the discrepancy.
5. Compute the new version from the last tag + bump type. All 5 packages move to this same new
   version regardless of whether their own code changed (matches repo history: e.g. 2.0.1→2.0.2
   bumped all 5 even though only some had real changes).
6. **Use AskUserQuestion to confirm the proposed version and bump type before touching any
   file.** Show the commit list and your reasoning. Let the user override.

## Step 3 — Bump versions

For each of the 5 packages (`nitrite`, `nitrite_generator`, `nitrite_hive_adapter`,
`nitrite_spatial`, `nitrite_support`):

1. In `packages/<pkg>/pubspec.yaml`, bump the top-level `version: OLD` to `version: NEW`.
2. For the 4 non-`nitrite` packages, also bump their runtime dependency constraint
   `nitrite: ^OLD` to `nitrite: ^NEW` in the same file's `dependencies:` block. (Leave any
   `nitrite_hive_adapter:`/`nitrite_generator:` version pins under `dev_dependencies:` alone
   unless you've separately confirmed the user wants that pre-existing staleness fixed — it's out
   of scope for a routine release.)
3. Update `packages/<pkg>/CHANGELOG.md`: add a new `## NEW` section at the top. For `nitrite`,
   draft real entries from the commit log (check what actually changed under
   `packages/nitrite/lib/`). For the other 4, check whether anything under their own `lib/`
   changed since the last tag; if yes, draft a real entry, if no, use the repo's established
   one-liner convention: `- Maintenance release: raised \`nitrite\` dependency to \`^NEW\`.`
4. Run `flutter pub get` at the repo root (workspace resolution) to confirm the version graph
   still resolves cleanly.

## Step 4 — Verify before committing

At minimum run the `nitrite` package's test suite:
`cd packages/nitrite && dart test test/integration/collection/ test/collection/operation/` (or
the fuller `melos run test-without-coverage` if time allows — note the repo has 2 pre-existing,
unrelated toolchain-flake test files, `test/nitrite_test.dart` and `test/spatial_rtree_test.dart`,
that can fail to *load* due to a Flutter-SDK switch-exhaustiveness issue independent of any code
change; don't let those two block a release, but do not wave away a failure in any other test
file). Do not proceed past a genuine red build.

## Step 5 — Commit and push

1. Commit the version bumps as `chore: bump packages to NEW` (matches repo convention — see
   `git log --oneline -- '**/pubspec.yaml'`), including all 5 `pubspec.yaml` and all 5
   `CHANGELOG.md` files. It's fine to split into two commits (e.g. `nitrite` alone, then the
   other 4) if that reads more clearly — the repo has done it both ways.
2. `git fetch origin --quiet` once more and confirm no new divergence, then `git push origin
   main`. Capture the resulting commit SHA — every tag below points at it.

## Step 6 — Tag and trigger the release (order and method matter — reread the pitfall above)

**This is the point of no return** — once `flutter pub publish --force` runs, the version is
permanently on pub.dev. Use AskUserQuestion one more time to get explicit go-ahead before this
step, showing the exact 5 tags and version about to be published.

**Always use each package's own CHANGELOG.md content as that release's notes — never
`--generate-notes`.** `--generate-notes` produces a bare "Full Changelog: compare-link" block
with no actual content, which is what happened the first time this was done manually and had to
be corrected afterward with `gh release edit --notes-file` for all 5 releases. Extract each
package's newly-added CHANGELOG section first:

```
for p in nitrite nitrite_generator nitrite_hive_adapter nitrite_spatial nitrite_support; do
  awk '/^## / && ++c==1 {next} /^## / && c==1 {exit} c==1 {print}' \
    packages/$p/CHANGELOG.md > /tmp/notes_$p.md
done
```

Then run these five, **in this exact order**, using the commit SHA from Step 5, and letting
`gh release create` mint each tag itself (do **not** `git tag` beforehand):

```
gh release create nitrite-NEW              --repo nitrite/nitrite-flutter --target <sha> --title "nitrite vNEW"              --notes-file /tmp/notes_nitrite.md
gh release create nitrite_generator-NEW    --repo nitrite/nitrite-flutter --target <sha> --title "nitrite_generator vNEW"    --notes-file /tmp/notes_nitrite_generator.md
gh release create nitrite_hive_adapter-NEW --repo nitrite/nitrite-flutter --target <sha> --title "nitrite_hive_adapter vNEW" --notes-file /tmp/notes_nitrite_hive_adapter.md
gh release create nitrite_spatial-NEW      --repo nitrite/nitrite-flutter --target <sha> --title "nitrite_spatial vNEW"      --notes-file /tmp/notes_nitrite_spatial.md
gh release create nitrite_support-NEW      --repo nitrite/nitrite-flutter --target <sha> --title "nitrite_support vNEW"      --notes-file /tmp/notes_nitrite_support.md
```

Verify afterward: `gh release view nitrite-NEW --repo nitrite/nitrite-flutter --json body -q
'.body'` (and likewise for the other 4) should print the drafted CHANGELOG prose, not a "Full
Changelog" compare-link block.

Immediately after, verify all 5 tags landed as lightweight:
`for t in nitrite-NEW nitrite_generator-NEW nitrite_hive_adapter-NEW nitrite_spatial-NEW
nitrite_support-NEW; do git fetch origin --tags --quiet; echo "$t: $(git cat-file -t "$t")"; done`
— every line must say `commit`, never `tag`. If any says `tag`, stop immediately: delete that
release and tag (`gh release delete <tag> --cleanup-tag`) and recreate it the same way before
proceeding — do not leave a broken tag in place hoping it'll trigger later, it won't.

Then confirm all 5 workflows actually started: `gh run list --repo nitrite/nitrite-flutter
--workflow=<pkg>-release.yml --limit 1` for each of the 5 workflow file names — each should show
a run with the matching tag as `headBranch` and `status` of `queued`/`in_progress` within ~30s of
creating the release.

## Step 7 — Wait and verify

Poll (use ScheduleWakeup at a few-minute cadence, or Monitor for a polling loop) all 5 run IDs
via `gh run view <id> --repo nitrite/nitrite-flutter --json name,status,conclusion` until every
one reports `status: completed`. Expect ~4 minutes each, running in parallel. For any that fail,
inspect with `gh run view <id> --log-failed` — do not blindly retry; a version that partially
published cannot be republished under the same number.

Once each workflow succeeds, verify the corresponding package actually reached pub.dev:
```
for p in nitrite nitrite_generator nitrite_hive_adapter nitrite_spatial nitrite_support; do
  echo "$p: $(curl -s https://pub.dev/api/packages/$p | jq -r '.latest.version')"
done
```
Every line must read `NEW`.

## Step 8 — Report

Summarize: old → new version, bump type and why, per-package workflow outcome and duration,
pub.dev confirmation per package, and the 5 GitHub Release URLs (note which one carries the
"Latest" badge).
