#!/usr/bin/env bash

REPO_URL="https://api.github.com/repos/steve-ross/direnv-helpers/releases/latest"

__prompt_install_nvm(){
  _log prompt "Couldn't find nvm (node version manager)..."
  read -p "Should I install it? " -n 1 -r
  echo    # (optional) move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    _log info "Installing NVM"
    curl -o- https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
    __source_nvm # make sure nvm is sourced
  else
    _log error "Install nvm first and make sure it is in your path and try again"
    _log warn "To install NVM visit https://github.com/creationix/nvm#installation"
    exit
  fi
}

__prompt_install_meteor(){
  _log prompt "Couldn't find meteor..."
  read -p "Should I install it? " -n 1 -r
  echo    # move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    _log info "Installing, this will take awhile."
    curl https://install.meteor.com/ | sh
  else
    _log error "Install meteor and try again"
    _log warn "To install NVM visit https://www.meteor.com/install"
    exit
  fi
}

__source_nvm(){
  local NVM_PATH=$(find_up .nvm/nvm.sh)
  [ -s "$NVM_PATH" ] && \. "$NVM_PATH"  # This loads nvm
}

__load_or_install_nvm(){
  local NVM_PATH=$(find_up .nvm/nvm.sh)
  if [ -z "$NVM_PATH" ]; then
    # didn't find it
    __prompt_install_nvm
  else
    # source NVM
    __source_nvm
  fi
}

__direnv_nvm_use_node(){
    local NVM_PATH=$(find_up .nvm/nvm.sh)
    NVM_PATH="${NVM_PATH/\/nvm.sh/}"
    local NODE_VERSION=$(< .nvmrc)
    
    # if the version id is an alias cat the file for the version
    if [ -f "$NVM_PATH/alias/$NODE_VERSION" ]; then
      NODE_VERSION=$(< $NVM_PATH/alias/$NODE_VERSION)
    fi

    # remove 'v' prefix for direnv 
    NODE_VERSION="${NODE_VERSION/v/}" 
    export NODE_VERSIONS="${NVM_PATH}/versions/node"
    export NODE_VERSION_PREFIX="v"
    

    if [ "$nvmrc_node_version" = "N/A" ]; then
      _log warn "Installing missing node version"
      local install_output=$(nvm install "$version" --latest-npm)
    fi
    use node $NODE_VERSION
}

__nvm_use_or_install_version(){
  local version=$(< .nvmrc)
  local nvmrc_node_version=$(nvm version "$version")
  if [ "$nvmrc_node_version" = "N/A" ]; then
    _log warn "Installing missing node version"
    local install_output=$(nvm install "$version" --latest-npm)
  fi
}

_log() {
  local msg=$*
  local color_normal
  local color_success
  
  color_normal=$(tput sgr0;)
  color_error=$(tput setaf 1;)
  color_success=$(tput bold; tput setaf 2;)
  color_warn=$(tput setaf 3;)
  color_info=$(tput setaf 6;)
  color_prompt=$(tput bold;)

  # default color
  current_color="${color_normal}"

  if ! [[ -z $2 ]]; then
    local message_type=$1
    # remove message type from the string (plus a space)
    msg=${msg/$message_type /}
    if [ "$message_type" = "warn" ]; then
      current_color="${color_warn}"
    fi
    if [ "$message_type" = "info" ]; then
      current_color="${color_info}"
    fi
    if [ "$message_type" = "success" ]; then
      current_color="${color_success}"
    fi
    if [ "$message_type" = "error" ]; then
      current_color="${color_error}"
    fi
    if [ "$message_type" = "prompt" ]; then
      current_color="${color_info}"
      color_normal="${color_prompt}"
    fi
  fi

  if [[ -n $DIRENV_LOG_FORMAT ]]; then
    # shellcheck disable=SC2059
    printf "${current_color}${DIRENV_LOG_FORMAT}${color_normal}\n" "$msg" >&2
  fi
}

function comparedate() {
  local MAXAGE=$(bc <<< '24*60*60') # seconds in 24 hours
  # file age in seconds = current_time - file_modification_time.
  if [ $(uname -s) == "Darwin" ]; then
    local FILEAGE=$(($(date +%s) - $(stat -f '%m' "$1")))
  else
    local FILEAGE=$(($(date +%s) - $(stat -c '%Y' "$1")))
  fi
  test $FILEAGE -gt $MAXAGE && {
      echo "Time to check for an update..."
  }
}

function getLatestVersion(){
  local NEW_VERSION="$(curl -s $REPO_URL | grep tag_name | cut -d'v' -f2 | cut -d'"' -f1)"
  # if it doesn't exist create it and set it to the latest version
  local CONFIG_FILE=$1
  if [ ! -f $CONFIG_FILE ]; then
    echo -n "$NEW_VERSION" > $CONFIG_FILE
  fi

  local CUR_VERSION="$(cat $CONFIG_FILE)"

  if [ -z "$CUR_VERSION" ];then
    # blank version... assume it's the first selfupdate version
    # (we'll check for another ) update in 24h so not a big deal
    CUR_VERSION=$NEW_VERSION
    echo -n "$CUR_VERSION" > $CONFIG_FILE
  fi

  
  # if [ "$NEW_VERSION" != "$CUR_VERSION" ]; then
  if [ "$NEW_VERSION" != "$CUR_VERSION" ]; then
    _log info "Updating helper to latest version $NEW_VERSION"
    # help on update/download
    # https://gist.github.com/steinwaywhw/a4cd19cda655b8249d908261a62687f8#gistcomment-2754696
    local target_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
    pushd /tmp/
    local file_url=$(curl -s $REPO_URL | grep "tarball_url" | cut -d'"' -f4)
    _log info $file_url
    local tarball="${NEW_VERSION}.tar.gz"
    _log warn $tarball
    curl -L --silent $file_url > $tarball
    mkdir $NEW_VERSION
    tar -xzf $tarball -C $NEW_VERSION
    local new_file="$(find ./${NEW_VERSION} -name "*.sh" 2>/dev/null)"

    _log info "Target dir ${target_dir}"
    # replace current script file
    mv -f $new_file $target_dir
    rm -rf $NEW_VERSION
    # update the version file
    echo -n "$NEW_VERSION" > $CONFIG_FILE
    echo $NEW_VERSION
  else
    # touch our config file so we don't re-run our update
    touch $CONFIG_FILE
  fi
}


__check_for_update(){
  local THIS_SCRIPT=${BASH_SOURCE[0]}
  local ARGS="$@"
  SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
  local CONFIG_FILE="$SCRIPT_DIR/.helpers-version"
  
  # if there is no version file create it with the latest release
  if [ ! -f $CONFIG_FILE ]; then
    getLatestVersion $CONFIG_FILE
  else
    # we have a version so see if we need to check (we'll check every 24h)
    local CHECK_FOR_UPDATE=$(comparedate $CONFIG_FILE)
    
    if [ ! -z "$CHECK_FOR_UPDATE" ];then
      _log info "Checking for update..."
      local NEW_VERSION=$(getLatestVersion $CONFIG_FILE)
      
      # if getLatestVersion returns a new version (var isn't empty)
      if [ ! -z "$NEW_VERSION" ];then
        _log success "Updated to latest version"
        echo "UPDATED"
      fi
    fi
  fi
}

requires_nvm(){
  _log warn "(.nvmrc detected) 'requires_nvm' no longer needed in .envrc and you may remove it"
}

__use_yarn(){
  local NOT_INSTALLED=$(which yarn)
  if [ -z "$NOT_INSTALLED" ]; then
    _log prompt "Couldn't find yarn..."
    read -p "Should I install it via homebrew? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      _log info "Installing yarn via homebrew..."
      brew install yarn
    else
      _log error "You'll need to install yarn before you can run the project"
      _log warn "Visit https://classic.yarnpkg.com/en/docs/install to learn how"
      exit
    fi
  else
    if [ ! -d ./node_modules ]; then
      _log warn "Installing packages"
      # no node modules... install via yarn
      yarn
    fi
    _log success "Good to go, 'yarn start' for local development"
  fi
}

__requires_npm_or_yarn(){
  if [[ -f "yarn.lock" && -f "package-lock.json" ]]; then
    # project misconfigured... has both package-lock.json and yarn.lock
    _log error "ERROR! This project has both a package-lock.json (npm install) and a yarn.lock (yarn)"
    _log warn "Exiting... you should remove one or the other and settle on one package manager"
  else
    if [ -f "yarn.lock" ]; then
      __use_yarn
    else
      if [ ! -d ./node_modules ]; then
        # no node modules... run npm install
        _log warn "Installing packages"
        npm install
      fi
    fi
  fi
}

requires_stencil(){
  _log warn "(package.json -> @bigcommerce/stencil-cli now detected) 'requires_stencil' no longer needed in .envrc and you may remove it."
}

layout_stencil(){
  # if cli is installed
  if ! has stencil; then
    _log warn "Installing stencil cli"
    npm install -g @bigcommerce/stencil-cli
  fi
  if [[ ! -f ".stencil" ]]; then
    # see if we have an environment variable w/the stencil config
    if [[ ! -z "$STENCIL_FILE" ]];then
     echo -n "$STENCIL_FILE" > .stencil
     _log success ".stencil written via Environment variable"
    else
    _log prompt "Couldn't find a .stencil config file ..."
      read -p "Init stencil? " -n 1 -r
      echo    # (optional) move to a new line
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        stencil init
      else
      _log warn "You'll need a .stencil file, check the project's README on how you should obtain a copy"
        exit
      fi
    fi
  fi

  
}

layout_envkey(){
  if ! has envkey-source; then
    _log warn "Installing EnvKey cli"
    curl -s https://raw.githubusercontent.com/envkey/envkey-source/master/install.sh | bash
  fi
  _log "Using EnvKey"
  eval "$(envkey-source)"
  
}

layout_shopify(){
  if ! has theme; then
    _log warn "Installing shopify themekit"
    # mac only here, need to detect this instead
    brew tap shopify/shopify && brew install themekit
  fi
  _log "Using Shopify Themekit"
}

requires_themekit(){
  _log warn "(Shopify now detected) 'requires_themekit' no longer needed in .envrc and you may remove it."
}
requires_envkey(){
  _log warn "(Envkey now detected) 'requires_envkey' no longer needed in .envrc and you may remove it."
}
requires_meteor(){
  _log warn "(.meteor folder detected) 'requires_meteor' no longer needed in .envrc and you may remove it."
}

layout_meteor(){
  if has meteor; then
    if [ ! -d ./node_modules ]; then
      # no node modules... run meteor npm install
      _log warn "Running meteor npm install"
      meteor npm install
    fi
  else
    __prompt_install_meteor
  fi
  _log success "Good to go, Meteor installed"
}
layout_nvm(){
  __load_or_install_nvm
  __nvm_use_or_install_version
  __direnv_nvm_use_node
  __requires_npm_or_yarn
}

layout_project(){
  # detect envkey
  if [[ -f ".env" && (! -z "$(grep -Fs "ENVKEY=" .env)" || ! -z "$ENVKEY")]]; then
    layout_envkey
  fi

  # if we have a package json do some node project detection 
  if [[ -f "package.json" ]]; then
    # set some env vars that might be useful
    # package version
    export NPM_PACKAGE_VERSION=$(cat package.json \
      | grep version \
      | head -1 \
      | awk -F: '{ print $2 }' \
      | sed 's/[ ",\t\r\n]//g'  )
    # package name
    export NPM_PACKAGE_NAME=$(cat package.json \
      | grep name \
      | head -1 \
      | awk -F: '{ print $2 }' \
      | sed 's/[ ",\t\r\n]//g'  )
    # if directory has .nvmrc assume nvm/node project
    if [[ -f ".nvmrc" ]]; then
      layout_nvm
    fi
    # look for bigcommerce stencil-cli if we don't have a .stencil file
    if [[ -f ".stencil" || ! -z "$(grep -Fs "@bigcommerce/stencil-cli" ./package.json)" || ! -z "$(grep -Fs "@bigcommerce/stencil-utils" ./package.json)" ]]; then
      layout_stencil
    fi
    # if meteor
    if [[ -d ".meteor" ]]; then
      layout_meteor
    fi
  fi
  
  # detect shopify themekit
  if [[ -f "config.yml" && ! -z "$(grep -Fs "theme_id:" config.yml)" ]]; then
    layout_shopify
  fi

}

main(){
  local UPDATED=$(__check_for_update)
  if [ -z "$UPDATED" ]; then
    layout_project
  else

ORIG_DIRENV_LOG_FORMAT="${DIRENV_LOG_FORMAT-direnv: %s}"
DIRENV_LOG_FORMAT="%s"
cat << "EOF"
    __         __                                       
   / /_  ___  / /___  ___  __________                   
  / __ \/ _ \/ / __ \/ _ \/ ___/ ___/                   
 / / / /  __/ / /_/ /  __/ /  (__  )                    
/_/ /_/\___/_/ .___/\___/_/  /____/                     
            /_/                  __      __           __
                __  ______  ____/ /___ _/ /____  ____/ /
               / / / / __ \/ __  / __ `/ __/ _ \/ __  / 
              / /_/ / /_/ / /_/ / /_/ / /_/  __/ /_/ /  
              \__,_/ .___/\__,_/\__,_/\__/\___/\__,_(_) 
                  /_/                                   
                  
                          Time to reload your shell!

EOF

DIRENV_LOG_FORMAT=$ORIG_DIRENV_LOG_FORMAT
    exit
  fi
}

main