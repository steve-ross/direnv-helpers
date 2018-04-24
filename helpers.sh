#!/usr/bin/env bash
__prompt_install_nvm(){
  _log warn "Couldn't find nvm (node version manager)..."
  read -p "Should I install it? " -n 1 -r
  echo    # (optional) move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    _log info "Installing NVM"
    curl -o- https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
    __source_nvm # make sure nvm is sourced
  else
    log_error "Install nvm first and make sure it is in your path and try again"
    _log warn "To install NVM visit https://github.com/creationix/nvm#installation"
    exit
  fi
}

__prompt_install_meteor(){
  _log info "Couldn't find meteor..."
  read -p "Should I install it? " -n 1 -r
  echo    # (optional) move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    _log info "Installing, this will take awhile."
    curl https://install.meteor.com/ | sh
  else
    log_error "Install meteor and try again"
    _log warn "To install NVM visit https://www.meteor.com/install"
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
    _log warn "Installing missing node version"
    local install_output=$(nvm install "$version")
  fi
  nvm use
}

_log() {
  local msg=$*
  local color_normal
  local color_success
  
  color_normal=$(tput sgr0)
  color_success=$(tput setaf 2)
  color_warn=$(tput setaf 3)
  color_info=$(tput setaf 5)

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
  fi

  if [[ -n $DIRENV_LOG_FORMAT ]]; then
    # shellcheck disable=SC2059
    printf "${current_color}${DIRENV_LOG_FORMAT}${color_normal}\n" "$msg" >&2
  fi
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
    _log success "Good to go, 'stencil start' for local development"
  fi
}

requires_stencil(){
  if has stencil; then
    __config_or_init_stencil
  else
    _log warn "Installing stencil cli"
    npm install -g @bigcommerce/stencil-cli
  fi
  
}

requires_themekit(){
  if has theme; then
    _log success "Found shopify themekit"
  else
    _log warn "Installing shopify themekit"
    # mac only here, need to detect this instead
    brew tap shopify/shopify
    brew install themekit
  fi
}

requires_meteor(){
  if has meteor; then
    if [ ! -d ./node_modules ]; then
      # no node modules... run meteor npm install
      _log warn "Running npm install"
      meteor npm install
    fi
  else
    __prompt_install_meteor
  fi
  _log success "Good to go, Meteor installed"
}