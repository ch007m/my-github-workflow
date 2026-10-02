# my-github-workflow

Project to test/practice GitHub workflow. Test 106

## PR test approval

Set the repository Actions variable `MAINTAINERS` to a JSON array of GitHub usernames, for example `["maintainer-one","maintainer-two"]`, to allow additional users to use `/ok-to-test` or `/stop-test` on a pull request. Repository owners, members, and collaborators (based on GitHub's `author_association`) can always use these commands, even without configuring this variable.

The `ok-to-test` label gates the PR test-and-package workflow. Only a latest `/ok-to-test` command from a listed maintainer authorizes tests; `/stop-test` revokes that approval. Once approved, tests also run for later PR commits while the label remains.
