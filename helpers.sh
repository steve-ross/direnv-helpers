#!/usr/bin/env bash
__prompt_install_nvm(){
  log_status "Couldn't find nvm (node version manager)..."
  read -p "Should I install it? " -n 1 -r
  echo    # (optional) move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_status "Installing NVM"
    curl -o- https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
    __source_nvm # make sure nvm is sourced
  else
    log_error "Install nvm first and make sure it is in your path and try again"
    log_status "To install NVM visit https://github.com/creationix/nvm#installation"
    exit
  fi
}


__npm_install_and_layout(){
  if [ ! -d ./node_modules ]; then
    # no node modules... run npm install
    npm install
  fi

  if [ -d node_modules/.bin ]; then
    # apply direnv's layout node so stuff in ./node_modules/.bin
    # acts like it is global
    layout_node
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
    # load version direnv way
    local NVM_NODE_VERSION_DIR=versions/node
    local NODE_VERSION=$(< .nvmrc)

    # two possible locations for node versions in nvm...
    local ALT_NVM_PATH="${NVM_PATH/\/nvm.sh}"
    local TYPICAL_NVM_PATH="${NVM_PATH/nvm.sh/$NVM_NODE_VERSION_DIR}"
    
    # set the nvm path to the typical place NVM stores node versions
    local NVM_PATH="$TYPICAL_NVM_PATH"

    #check alt path (seems old versions are here)
    if [ -d "$ALT_NVM_PATH/v$NODE_VERSION" ]; then
      NVM_PATH="$ALT_NVM_PATH"
    fi

    export NODE_VERSIONS=$NVM_PATH
    export NODE_VERSION_PREFIX="v"
    
    use node
}

__nvm_use_or_install_version(){
  local version=$(< .nvmrc)
  local nvmrc_node_version=$(nvm version "$version")
  if [ "$nvmrc_node_version" = "N/A" ]; then
    log_status "Installing missing node version"
    local install_output=$(nvm install "$version")
  fi
  nvm use
}

requires_nvm(){
  __load_or_install_nvm
  __nvm_use_or_install_version
  __direnv_nvm_use_node
  __npm_install_and_layout
}

__config_or_init_stencil(){
  local STENCIL_CONFIG=$(find .stencil)
  if [ -z "$STENCIL_CONFIG" ]; then
    stencil init
  else
    log_status "Good to go, 'stencil start' for local development"
  fi
}

requires_stencil(){
  if has stencil; then
    __config_or_init_stencil
  else
    log_status "Installing stencil cli"
    npm install -g @bigcommerce/stencil-cli
  fi
  
}

requires_themekit(){
  if has theme; then
    log_status "Found shopify themekit"
  else
    log_status "Installing shopify themekit"
    # mac only here, need to detect this instead
    brew tap shopify/shopify
    brew install themekit
  fi
}