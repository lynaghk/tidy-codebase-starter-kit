# Tidy codebase starter kit

*WARNING: This is a work-in-progress and written imperatively for clarity, not necessarily because I'm strongly convinced. I'm just working in public so I can share with friends and get feedback. Feel free to open an issue if you want to chat about this sort of stuff. --kevin*


## Overview

My favorite codebases are *easy to run*:

+ They can be cloned onto a new machine and all dependencies installed with a single command.
+ Starting a development environment, running the test suite, or packaging a release can all be done with a single command.

My favorite codebases are also *tidy*:

+ The code is consistently formatted.
+ Commits have meaningful messages describing atomic changes.
+ The history is organized as features developed on branches and merged back into a main branch.

However, it's hard to keep codebases easy-to-run and tidy:

+ In most languages, it's easy to accidentally depend on un-tracked stuff like compiler versions and system libraries, leading to reproducibility problems ("it works on my machine").
+ It can be easy to forget to run code formatters, linters, and tests before committing --- especially for new or casual contributors who may not even know about such things!
+ Even if such tools are run, their results may not reflect what actually goes it the commit (because of staged hunks, working tree files hidden by `.gitignore`, etc.).

Continuous integration (CI) servers can help, but the developer experience isn't great:

+ Failure notifications are delayed --- not just from the latency of the CI server noticing the commit, but also the typically slower performance of cloud servers compared to a developer's local system.
+ Notifications come over a separate channel (e.g., email, Slack bot) than the one where the developer is focused when committing changes (their terminal or Git UI).
+ Since the failing commit has already been pushed, the developer needs to either force-push an amended commit (impolite on shared branches) or create an entirely new commit that fixes the issue (cluttering the history with "oops" and "try running ci again" commits).
+ CI is annoying to administer anyway, as you need to either run your own server or rely on the API stability and uptime guarantees of someone else's service.


## Goals

Wouldn't it be neat if we could keep a runnable, tidy codebase with a *local* workflow that:

+ Eliminates "it works for me" errors caused by differences between developer machines.
+ Isn't tied to a particular language ecosystem.
+ Is fast enough to use regularly during development (< 1s overhead).
+ Can be learned quickly, with minimal cognitive burden from new concepts or leaky implementation abstractions.
+ Maintains a branch where tests always pass (the ["not rocket science"](https://graydon2.dreamwidth.org/1597.html) rule).


## Assumptions and non-goals

+ Platform independence: I'm developing on Mac and deploying to Linux (both aarch64), so that's what this starter kit assumes.
+ Reproducible builds: It's a [good idea](https://reproducible-builds.org/) but the ROI isn't there for me to use [Nix](https://nixos.org/) and/or try to eliminate all of the sources of nondeterminism through my operating system, virtual machine, language interpreter/compiler, and dependency stacks.
+ Archival quality: I'm thinking on a timescale of ~10 years and assume resources not checked into this repo (e.g., Ubuntu packages, git, docker, etc.) will have either maintained backwards compatibility or have widely available older versions suitable to build my projects.
+ Scalability: My team size and development velocity allow a local "merge, test, push" strategy to succeed without coordination (otherwise, see [keeping master green at scale](https://blog.acolyer.org/2019/04/18/keeping-master-green-at-scale/) and tools like [bors-ng](https://github.com/bors-ng)).
+ Security: A motivated person can bypass this local workflow and push to whatever remotes they're authorized to, so the workflow assumes cultural alignment around the value of tidiness.


## The Workflow

Okay! That was a lot of background and motivation.
Here's the workflow, it's very boring!

To initially setup a dev machine, clone this repository and run:

    ./scripts/bootstrap.sh
    
You will be prompted to install [Docker Desktop](https://docs.docker.com/desktop/install/mac-install/) if necessary.
This script will also configure git hooks and configuration to support the [collaborative development rules of thumb](#collaborative-development-rules-of-thumb) described below.

Then for a live-reloading development server:

    toast dev

to test:

    toast test

and to build a production release:

    toast release
    
   

## Implementation overview

[Toast](https://github.com/stepchowfun/toast) runs commands within Docker containers, caching them when inputs haven't changed.
This enables sufficiently reproducible environments (modulo `apt-get update` and other unlocked dependencies, timestamps, etc.) under which project code can be run.

The git hooks in `/scripts/git-hooks/` are installed by the bootstrap script.

The pre-commit hook formats code, so formatting commits don't clutter the repository history (of course, a format commit will be necessary whenever the formatting rules are changed).

The pre-push hook runs only when pushing to `main`, when it runs `toast test` on *all* commits to be pushed.
It does this by cloning the repository to a temporary directory, checking out the commits to be pushed (oldest to newest), and running the tests, stopping at the first failure.

The pre-merge hook prevents merging the `main` branch into *any other branch*, since this almost always leads to a cluttered history (commits like "merge branch 'main' into my-feature").
This hook will remind you to rebase instead.


## Collaborative development rules of thumb

+ The `main` branch should always be in a working state (build, have passing tests, etc.).
+ Commits should be meaningful on their own (not "halfway done"), and have descriptive, present-tense messages.
+ Work that'll take multiple commits should be done on feature branches:
  + On these branches, anything goes (work-in-progress commits, force-push updates, etc.).
  + When work is ready to be reviewed:
    + The branch should be rebased onto the latest `main` (to prevent conflicts when merging).
    + The commits should be cleaned up to tell a coherent story (also via git rebase)
  + After review approval, the branch is merged; fast forwarding is appropriate only for a single-commit branch; otherwise a merge commit should be used to retain the branch's individual commits in the history.
+ Merge commits in `main` are only appropriate when they reflect meaningful work (i.e., the merge commit's second parent is a series of commits that together make up a feature).
+ Minimize the number of feature branches open at any time; such work-in-progress is a future integration liability and tends to increase overall cycle-time.


In terms of tooling:

+ Consider enabling [git rerere](https://medium.com/@porteneuve/fix-conflicts-only-once-with-git-rerere-7d116b2cec67) so you don't have to fix the same conflict multiple times when rebasing.

+ [GitUp](https://gitup.co/) is a free graphical Git interface that makes the repository structure clear.


## Alternatives considered / Misc. notes / TODO

Earthly is substantially more feature-rich than toast, but it had [too much overhead](https://github.com/earthly/earthly/issues/2049) and the complexity didn't provide sufficient value for my needs.

It'd be neat to use `DOCKER_HOST` for remote execution, but this adds about [1s of additional overhead](https://github.com/stepchowfun/toast/issues/440) and [doesn't work with bind mounts](https://github.com/stepchowfun/toast/issues/441), which means we can't run commands on against local files (breaking interactive editor and live-reload workflows).

How "turnkey" should the bootstrap script be? Should it automatically install docker and toast, to make things as easy as possible for non-programmers to contribute to the repo?
That'd be useful when collaborating with electrical/mechanical engineers, scientists, operations folks, etc.

Should the pre-push test script be written in bash, or is the "test each commit in an isolated working directory" logic complex enough to warrant a more robust language?

Fork toast to make a single kitchen-sink binary supporting the entire workflow, including the git hook testing logic and possibly [rtss](https://github.com/Freaky/rtss)-like timestamp output on everything so workflow performance is always top-of-mind?
