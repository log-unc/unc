# Log-Unc

Log-Unc is a single-file Luau diagnostic that measures how accurately a Roblox
environment logger reproduces the real engine. It runs over 1200 checks across
the DataModel, instance behaviour, datatypes, the Luau standard library, the
task scheduler, physics, GUI, undocumented service hierarchies and the common
executor API surface.

A real Roblox client scores 100% with zero failures and zero skips. Anything
lower is a gap in the sandbox being tested.

## Running the diagnostic

Copy `Log-Unc-V1.lua` and run it in your environment logger, or load it from the
site if `loadstring` and `HttpGet` are available:

```lua
loadstring(game:HttpGet("https://log-unc.workers.dev/script.lua"))()
```

The final lines print the score, every failed and skipped check with its
reason, and the collected metrics.

## Submitting a result

Results are stored in the repository, one JSON file per logger. There is no API
key and no server-side database.

1. Run the diagnostic and copy the whole console output.
2. Open the Submit tab on the site, paste the output, and download the
   generated JSON file.
3. Add that file to `site/loggers/` and open a pull request.

The file format is:

```json
{
  "name": "Example Logger",
  "author": "your-handle",
  "url": "https://github.com/your/logger",
  "submittedAt": "2026-01-01",
  "output": "12:00:00 -- [PASS] game is DataModel\n..."
}
```

Only `name` and `output` are required. The file name becomes the URL slug.

On every push the build parses each submission, rejects malformed files,
duplicate slugs and outputs with no recognisable checks, then writes the static
JSON the site reads. Identifying metrics such as `UserId`, `DisplayName`,
`ClientId` and `ExecutorHwid` are stripped before publication.

## Local development

```
cd site
node scripts/test.mjs
node scripts/build.mjs
npx wrangler dev
```

`scripts/build.mjs` regenerates `public/data/`, copies the diagnostic to
`public/script.lua` and vendors the parser for the browser. Those outputs are
generated, not committed.

## Layout

```
Log-Unc-V1.lua          the diagnostic
site/loggers/           submitted results, one JSON file per logger
site/scripts/build.mjs  parses submissions into static JSON
site/scripts/test.mjs   parser tests
site/src/parser.mjs     shared parser used by the build and the browser
site/src/worker.js      Cloudflare Worker serving the static site
site/public/            site source
```
