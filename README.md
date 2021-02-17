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

### Change Log / Release Notes

- Version 0.3.3 (Hotfix)
  - Hotfix to write newer stencil config files for BigCommerce
    - New variables $CONFIG_STENCIL_JSON and $SECRETS_STENCIL_JSON 
- Version 0.3.2
  - Better BigCommerce Detection (detect stencil-utils package)
- Version 0.3.1
  - Fix whitespace in NPM Environment Variables
- Version 0.3.0 
  - Export NPM_PACKAGE_NAME NPM_PACKAGE_VERSION
  - Date Detect - Handle non-mac environments (Thx for the PR!) 
- Version 0.2.0 
  - auto detect shopify, bigcommerce, envkey
  - automatically download stencil file from EnvKey if we find the variable $STENCIL_FILE
  - depricate old helpers: requires_stencil, requires_themekit, requires_envkey
- Version 0.1.0
  - check for updates and download when a new release is available
    - writes version string to .helpers-version in the same directory as helpers.sh
    - only check for a new version every 24h
  - added auto=detecting project types
     - look for .nvmrc and assume project is using nvm
     - look for .meteor directory and assume project is using meteor
  - don't call nvm use since direnv is loading node
  - abandon using log_error... just call _log error "something bad happened..."
- Version 0.0.4 
  - detect yarn.lock vs package-lock.json and install yarn if needed
- Version 0.0.3 
  - bugfix for when .nvmrc contains a release name ie: 'lts/dubnium'
- Version 0.0.2 
  - don't assume 'layout node' when using node
- Version 0.0.1 
  - Initial release
