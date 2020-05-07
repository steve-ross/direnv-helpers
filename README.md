# Various helpers for direnv.net (NVM, BigCommerce, Shopify, Meteor)
### Handy project setup helpers that can:

- Auto updates itself if a new version is detected in github
- Detect & install yarn
- Detect misconfigured project (has both yarn.lock and package-lock.json)
- Auto-Detect & install NVM
- Auto-Detect & install BigCommerce's stencil-cli
- Auto-Detect & install Meteor
- Auto-Detect & install Shopify's themekit
- Auto-Detect & install EnvKey (and call envkey-source)
- Node / NVM specific helpers
  - Use the node version required by your project (if missing, install it with NVM)
  - Run npm install if you are missing a `node_modules`
  - Use direnv's `node_layout` to make any `./.bin` stubs available in your shell


## Installation

```
# one liner
curl -o ~/.config/direnv/helpers.sh --create-dirs https://raw.githubusercontent.com/steve-ross/direnv-helpers/master/helpers.sh && echo -n "source ~/.config/direnv/helpers.sh" >> ~/.config/direnv/direnvrc

# OR...
# download the script
curl -o ~/.config/direnv/helpers.sh --create-dirs https://raw.githubusercontent.com/steve-ross/direnv-helpers/master/helpers.sh

# source it in your ~/.config/direnv/direnvrc
echo -n "source ~/.config/direnv/helpers.sh >> ~/.config/direnv/direnvrc
```

## How to use the helpers in your projects (NVM example)

You don't even need NVM installed yet, this script will detect if it exists and prompt for installation in your project directory if it isn't.

Make sure `direnv.net` is installed and working in your shell (For MacOS just install via homebrew) `brew install direnv` and follow the prompts to have it auto load in your shell

First: If you don't already have one, create a `.nvmrc` file and specify your node version

```
echo "8.8.1" >> .nvmrc
```

Next: Create a `.envrc` file

Direnv should prompt you to allow the script to run and voila!

## Auto-detect your project layout - all you need is a .envrc (it can be empty even!)
 
```bash
# .envrc
dotenv
```

```bash
# .env
ENVKEY=my_super_cool_key
```


## Development

clone the repo and link the helpers manually to the location you cloned the project

Steps to Test self-update
1. add anything to the .helpers-version file (so they don't match current)
2. adjust the timestamp/lastupdated time of .helpers-version so the file is older than 24 hours `touch -mt 200801120000 .helpers-version`
