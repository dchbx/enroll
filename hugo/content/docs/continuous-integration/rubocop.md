---
title: "Rubocop"
---

# Rubocop

The first check in our continuous integration pipeline is [Rubocop](https://rubocop.org/). This is a linter that is [configured](https://github.com/dchbx/enroll/blob/master/.rubocop.yml) to check various coding styles and formatting.

Rubocop is meant to be run on specific files or an entire codebase. When pushing code to a remote branch, it's not efficient (or valuable) to run this check on the entire codebase, so we use a library called [rubocop-git](https://github.com/m4i/rubocop-git). This library runs rubocop on just the code that has changed when comparing a feature branch to the default branch.

## Catching and Fixing Errors with Rubocop

You can (and should) run Rubocop locally. Doing so will help you to catch mistakes before they get to our CI Pipeline. You can run rubocop-git _or_ run rubocop itself. Each present an opportunity to catch errors and fix them.

### Run rubocop-git locally

Running rubocop-git is a great way to find errors in the code that you've personally added. Run it with `bundle exec rubocop-git origin/master`. Any errors will print to your console and you can get to fixing them.

### Run rubocop locally

Running rubocop with no additional arguments will scan the entire codebase. This probably isn't what you want. Instead, provide a path like `rubocop app\controllers\families_controller.rb` to have rubocop analyze that specific file. One flag worth mentioning is `-a` which will auto-correct offenses.

## Rubocop in GitHub Actions

When we run rubocop in GitHub Actions, the exact set of commands that are run are:

``` bash
git config diff.renameLimit 800
git fetch --no-tags --depth=1 origin master
bundle exec rubocop-git origin/master | grep "no offenses detected"
```

1. `git config ...` deals with some shortcomings of git in a large codebase.
2. `git fetch ...` fetches the `master` branch but without tags and only to a depth of 1, i.e. only the most recent commit.
3. `bundle exec ...` is the command we use to run rubocop-git
4. `grep "no offenses detected"` is somewhat of a hack to get the output to only "error" if we _don't_ see that phrase

### Failures at the Rubocop step

If your branch does not pass the Rubocop step in GitHub Actions, you're likely to see this:
``` bash
Run git config diff.renameLimit 800
From https://github.com/dchbx/enroll
 * branch            master     -> FETCH_HEAD
 * [new branch]      master     -> origin/master
Error: Process completed with exit code 1.
```
There isn't more to go on because of a deficiency in rubocop-git. Thankfully, there are only two reasons why you'd see this error:

1. Your branch is out of date with the default branch
2. You are trying to add code that violates some Rubocop rule

### Branch is out of date with default

If your branch is out of date with the default branch, you should rebase your branch with the most recent version of `master`:
- `git checkout origin/master`
- `git pull`
- `git checkout <your-feature-branch>`
- `git rebase master`
- `bundle exec rubocop-git origin/master`

### Branch has actual errors in it

While this is not strictly necessary to do before _every_ push to the remote branch, it can certainly save time troubleshooting. Assuming your local copy of `master` is up-to-date, simply run rubocop-git locally: `bundle exec rubocop-git origin/master`.