# Release Process

ProspectMate releases are packaged by GitHub Actions with the BigWigsMods WoW packager.

## One-time setup

1. Create the addon project on CurseForge.
2. Add the CurseForge project id to `ProspectMate.toc`:

   ```toc
   ## X-Curse-Project-ID: 123456
   ```

3. Optional: create the addon project on Wago and add its id to `ProspectMate.toc`:

   ```toc
   ## X-Wago-ID: abc123
   ```

4. Add these GitHub repository secrets:

   - `CF_API_KEY` for CurseForge publishing
   - `WAGO_API_TOKEN` for Wago publishing, if using Wago
   - `WOWI_API_TOKEN` for WoWInterface publishing, if using WoWInterface

`GITHUB_TOKEN` is provided by GitHub Actions automatically and is used to create the GitHub Release.

## Releasing a version

1. Update `## Version:` in `ProspectMate.toc`.
2. Commit the release changes.
3. Create an annotated tag matching the addon version:

   ```powershell
   git tag -a v2.0.0 -m "ProspectMate v2.0.0"
   ```

4. Push the commit and tag:

   ```powershell
   git push origin master --follow-tags
   ```

The release workflow runs when a `v*` tag is pushed. It builds `ProspectMate-vX.Y.Z.zip`, creates a GitHub Release, and uploads to any configured addon host whose project id and API token are present.

You can also run the `Release` workflow manually from GitHub Actions. Manual runs use the packager's dry-run mode and upload the zip as a workflow artifact instead of publishing it to addon hosts.

## Notes

- CurseForge publishing needs both `## X-Curse-Project-ID` in the TOC and the `CF_API_KEY` secret.
- Wago publishing needs both `## X-Wago-ID` in the TOC and the `WAGO_API_TOKEN` secret.
- WoWInterface publishing needs both `## X-WoWI-ID` in the TOC and the `WOWI_API_TOKEN` secret.
- The packager generates release notes from commits since the previous tag.
