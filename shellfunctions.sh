### ────────────────────────────
### 🗂 Safe Move (instead of delete)

safe_move() {
  mv -i "$@" /tmp/
}

### ────────────────────────────
### 📦 Extract Archive

extract_archive() {
  [[ -z "$1" ]] && { echo "Usage: extract_archive <file>"; return 1; }
  [[ ! -f "$1" ]] && { echo "'$1' is not a valid file"; return 1; }

  case "$1" in
    *.tar.bz2) tar xjf "$1" ;;
    *.tar.gz)  tar xzf "$1" ;;
    *.bz2)     bunzip2 "$1" ;;
    *.rar)     unrar x "$1" ;;
    *.gz)      gunzip "$1" ;;
    *.tar)     tar xf "$1" ;;
    *.tbz2)    tar xjf "$1" ;;
    *.tgz)     tar xzf "$1" ;;
    *.zip)     unzip "$1" ;;
    *.Z)       uncompress "$1" ;;
    *.7z)      7z x "$1" ;;
    *.deb)     ar x "$1" ;;
    *.tar.xz)  tar xf "$1" ;;
    *.tar.zst) unzstd "$1" ;;
    *)         echo "'$1' cannot be extracted" ;;
  esac
}

### ────────────────────────────
### 🔒 Create Backup Archive

create_backup() {
  [[ -z "$1" ]] && { echo "Usage: create_backup <directory>"; return 1; }

  local TARGET
  TARGET=$(realpath "$1" 2>/dev/null) || {
    echo "Invalid path: $1"
    return 1
  }

  [[ ! -d "$TARGET" ]] && {
    echo "Not a directory: $TARGET"
    return 1
  }

  [[ -z "$BACKUP" ]] && {
    echo "BACKUP path not set"
    return 1
  }

  mkdir -p "$BACKUP"

  local DIR_NAME PARENT_DIR TIMESTAMP ARCHIVE
  DIR_NAME=$(basename "$TARGET")
  PARENT_DIR=$(dirname "$TARGET")
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)

  ARCHIVE="$BACKUP/${DIR_NAME}_${TIMESTAMP}.tar.gz"

  tar -czf "$ARCHIVE" -C "$PARENT_DIR" "$DIR_NAME" || {
    echo "Backup failed"
    return 1
  }

  echo "✔ Backup created:"
  echo "  $ARCHIVE"
}

### ────────────────────────────
### 📂 Extract Tar.gz

extract_tar() {
  [[ -z "$1" ]] && { echo "Usage: extract_tar <archive>"; return 1; }
  tar -xzf "$1"
}

### ────────────────────────────
### 🔍 System Insights

check_packages() {
  echo "APT packages     : $(dpkg -l | grep ^ii | wc -l)"
  echo "Cargo packages   : $(cargo install --list | grep ' v' | wc -l)"
  echo "Go packages      : $(ls $(go env GOPATH)/bin 2>/dev/null | wc -l)"
  echo "Python (user)    : $(pip list --user | wc -l)"
  echo "Python (system)  : $(pip list | wc -l)"
  echo "Ruby gems        : $(gem list | wc -l)"
  echo "npm (global)     : $(npm list -g --depth=0 2>/dev/null | grep '──' | wc -l)"
  echo "Flatpak apps     : $(flatpak list 2>/dev/null | wc -l)"
  echo "Snap packages    : $(snap list 2>/dev/null | wc -l)"
}
