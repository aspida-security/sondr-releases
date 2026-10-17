# Sondr

**A flight recorder for your terminal.** Sondr remembers the commands you run and whether they
worked, so when something breaks it can tell you what to check next, and why.

*by [Aspida Security](https://github.com/aspida-security)*

## Install

On Debian, Ubuntu, Kali or most other Linux machines (x86_64 or arm64):

```sh
curl -fsSLO https://github.com/aspida-security/sondr-releases/releases/latest/download/install.sh
less install.sh        # optional: read it first (press q to quit)
sh install.sh
```

The installer downloads only from this page's releases, checks the SHA-256 checksum, and stops if
it doesn't match. On Debian-family systems it installs the `.deb` with `apt` (it will ask for your
password); elsewhere it puts the program in `~/.local/bin`. Prefer to do it by hand? Download the
`.deb` or the `.tar.gz` and `SHA256SUMS` from the [Releases](../../releases) page.

If you are comfortable with it, the one-liner is
`curl -fsSL https://github.com/aspida-security/sondr-releases/releases/latest/download/install.sh | sh`.

## Start

Type:

```sh
sondr
```

That's it. The first time, Sondr walks you through a short setup: it asks how much you want it to
explain, shows the exact short block it will add to your shell's startup file, and lets you pick how
the recording light looks. Then open a new terminal window. If you want a guided practice run, say
yes to the tour, or type `sondr tour` any time.

## The recording light

Sondr puts a small light at the start of your prompt so you always know whether it is recording:

| You see | It means |
|---|---|
| `● rec` (red) | Recording in this terminal |
| `○ off` (dim) | Paused in this terminal (`sondr off`). Nothing you type is saved. `sondr on` resumes. |
| `● rec #7` | A case is open (case number 7) |
| `● rec #7 !` (yellow) | The open case looks stuck: you may be repeating yourself |
| `tour 2/6` | You are in the middle of the tour |

You can change the style with `sondr config set render.indicator blocks` (four squares, one lit, that
move each time the prompt redraws: a heartbeat, not an animation) or `off`. On a terminal without
UTF-8 you get `[REC]` and `[off]`, and `NO_COLOR` is respected.

## A 60-second example

```sh
$ npm test                         # something fails
$ sondr open "tests failing"       # tell Sondr what you're trying to fix
$ sondr run -- npm test            # run it again so Sondr can read the output
$ sondr next                       # ranked, read-only things to check, each with a reason
$ sondr why 1                      # why it suggested the first one
$ sondr close --solved "missing DATABASE_URL in .env"
```

Sondr only suggests. It never runs the commands it suggests.

## Privacy, in plain words

- Everything stays on your computer. There is no account, no telemetry, no update check, and no
  tracking of any kind.
- Passwords, keys and tokens are masked before anything is saved or shown.
- Sondr talks to the network only if you ask: `sondr feedback` opens your browser to a prefilled
  GitHub issue (after showing you exactly what it contains), and, if you choose to, it can talk to
  an Ollama running on your own computer.
- `sondr privacy` lists what is stored and where. `sondr forget --all` deletes it.

## Other handy commands

`sondr map` (where logs, settings and programs live) · `sondr explain 'some command'` (what it does,
without running it) · `sondr learn` (ideas you've met) · `sondr doctor` (checks that everything is
healthy) · `sondr help` (everything) · `sondr feedback` (tell us what to fix)

## Uninstall

```sh
sondr uninstall          # removes the lines in your shell startup file; keeps your history
sudo apt remove sondr    # removes the program (or delete ~/.local/bin/sondr)
```

Run `sondr uninstall` first. If you remove the program first, your terminal keeps working (the lines
in its startup file check that Sondr exists); you can delete those lines by hand. They sit between
`# >>> sondr >>>` and `# <<< sondr <<<`.

## Licence

Sondr is free to use, for personal and commercial work, under the
[Elastic License 2.0](LICENSE). It is not open source: you may not offer it to others as a hosted
service, and you may not remove licence-key functionality or notices.

## Feedback

Bugs, ideas, and "Sondr suggested something wrong" reports are welcome as
[issues](../../issues/new/choose), or type `sondr feedback`.

---

*Sondr is by [Aspida Security](https://github.com/aspida-security).*
