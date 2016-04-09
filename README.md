# example-travis-upstream
Example repository for a upstream/downstream setup. This is upstream.

## Settings

If you want to try this setup, fork both this and the downstream repository and modify the following vars in `travis.yml`:

- `DOWNSTREAM_REPO`: `{user}/{repo}` point to your downstream fork
- `secure: [... gibberish ...]` These need to be replaced by secret tokens for GitHub and Travis.

### GitHub token

You can either go the road of [registering this as your own application](https://github.com/settings/applications/new) and authorizing this using GitHubs automated OAUTH token generation,
or we simply create a restricted personal token.

For my usecase the laster was enough, so thats why I document this here.

Got to [your personal token settings](https://github.com/settings/tokens) and create a new token with scope `repo:status`.
This will allow this script to change the build status of all repositories you have push access to.
Copy this token and save locally. **DON'T PUT THIS TOKEN UNENCRYPTED INTO YOUR TRAVIS CONFIG**

Now install the travis cli and [encrypt your token](https://docs.travis-ci.com/user/encryption-keys/). This will look something like this:

```
travis login
travis encrypt -r ${UPSTREAM_REPO} GITHUB_TOKEN=${YOUR_TOKEN}
```

Where `${UPSTREAM_REPO}` for me would be `TheMarex/example-travis-upstream`.

Copy the result in the `.travis.yml`.

### Travis token

We also need a token for travis. We already installed the cli, so this will be simple:

```
travis login
travis token # copy this
travis encrypt -r ${UPSTREAM_REPO} TRAVIS_TOKEN=${TRAVIS_TOKEN}
```

Put the result again in your `.travis.yml`.

