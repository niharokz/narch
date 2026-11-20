#!/bin/bash
 
#
#       ███╗   ██╗██╗██╗  ██╗ █████╗ ██████╗ ███████╗
#       ████╗  ██║██║██║  ██║██╔══██╗██╔══██╗██╔════╝
#       ██╔██╗ ██║██║███████║███████║██████╔╝███████╗
#       ██║╚██╗██║██║██╔══██║██╔══██║██╔══██╗╚════██║
#       ██║ ╚████║██║██║  ██║██║  ██║██║  ██║███████║
#       ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
#       DRAFTED BY [https://nih.ar] ON 07-10-2026
#       SOURCE [shellfunctions.sh] LAST MODIFIED ON 07-10-2026
#



### ────────────────────────────
### 🗑 Safe Remove (backup before delete)

safe_move() {
  [[ -z "$1" ]] && {
    echo "Usage: rmv <file|directory>"
    return 1
  }

  local TARGET="$1"

  [[ ! -e "$TARGET" ]] && {
    echo "Not found: $TARGET"
    return 1
  }

  [[ -z "$BACKUP" ]] && {
    echo "BACKUP path not set"
    return 1
  }

  mkdir -p "$BACKUP" || {
    echo "Failed to create backup directory: $BACKUP"
    return 1
  }

  local REAL_TARGET NAME PARENT TIMESTAMP ARCHIVE

  REAL_TARGET=$(realpath "$TARGET" 2>/dev/null) || {
    echo "Invalid path: $TARGET"
    return 1
  }

  NAME=$(basename "$REAL_TARGET")
  PARENT=$(dirname "$REAL_TARGET")
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)

  ARCHIVE="$BACKUP/${NAME}_${TIMESTAMP}.tar.gz"

  echo "📦 Creating backup..."
  echo "   $REAL_TARGET"

  tar -czf "$ARCHIVE" -C "$PARENT" "$NAME" || {
    echo "❌ Backup failed — nothing deleted"
    rm -f -- "$ARCHIVE"
    return 1
  }

  echo "✔ Backup created:"
  echo "  $ARCHIVE"

  echo "🗑 Removing:"
  echo "  $REAL_TARGET"

  rm -rf -- "$REAL_TARGET" || {
    echo "❌ Delete failed"
    echo "⚠ Backup is still available:"
    echo "  $ARCHIVE"
    return 1
  }

  echo "✔ Removed successfully"
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
  [[ -z "$1" ]] && { echo "Usage: create_backup <directory> [exclude ...]"; return 1; }

  local TARGET
  TARGET=$(realpath "$1" 2>/dev/null) || { echo "Invalid path: $1"; return 1; }
  [[ ! -d "$TARGET" ]] && { echo "Not a directory: $TARGET"; return 1; }
  [[ -z "$BACKUP" ]] && { echo "BACKUP path not set"; return 1; }
  mkdir -p "$BACKUP"

  local DIR_NAME PARENT_DIR TIMESTAMP ARCHIVE x
  DIR_NAME=$(basename "$TARGET")
  PARENT_DIR=$(dirname "$TARGET")
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  ARCHIVE="$BACKUP/${DIR_NAME}_${TIMESTAMP}.tar.gz"

  # extra args = paths inside the directory to leave out
  local EXCLUDES=()
  for x in "${@:2}"; do EXCLUDES+=(--exclude="$DIR_NAME/$x"); done

  tar -czf "$ARCHIVE" "${EXCLUDES[@]}" -C "$PARENT_DIR" "$DIR_NAME" || { echo "Backup failed"; return 1; }

  echo "✔ Backup created:"
  echo "  $ARCHIVE"
}

# create_backup() {
#   [[ -z "$1" ]] && { echo "Usage: create_backup <directory>"; return 1; }
# 
#   local TARGET
#   TARGET=$(realpath "$1" 2>/dev/null) || {
#     echo "Invalid path: $1"
#     return 1
#   }
# 
#   [[ ! -d "$TARGET" ]] && {
#     echo "Not a directory: $TARGET"
#     return 1
#   }
# 
#   [[ -z "$BACKUP" ]] && {
#     echo "BACKUP path not set"
#     return 1
#   }
# 
#   mkdir -p "$BACKUP"
# 
#   local DIR_NAME PARENT_DIR TIMESTAMP ARCHIVE
#   DIR_NAME=$(basename "$TARGET")
#   PARENT_DIR=$(dirname "$TARGET")
#   TIMESTAMP=$(date +%Y%m%d_%H%M%S)
# 
#   ARCHIVE="$BACKUP/${DIR_NAME}_${TIMESTAMP}.tar.gz"
# 
#   tar -czf "$ARCHIVE" -C "$PARENT_DIR" "$DIR_NAME" || {
#     echo "Backup failed"
#     return 1
#   }
# 
#   echo "✔ Backup created:"
#   echo "  $ARCHIVE"
# }

### ────────────────────────────
### 📂 Extract Tar.gz

extract_tar() {
  [[ -z "$1" ]] && { echo "Usage: tr <archive(.tar.gz|.gpg)>"; return 1; }

  local FILE="$1"
  local TMP_ARCHIVE

  [[ ! -f "$FILE" ]] && {
    echo "File not found: $FILE"
    return 1
  }

  # If GPG encrypted
  if [[ "$FILE" == *.gpg ]]; then
    [[ -z "$PWDM" ]] && {
      echo "PWDM env variable not set"
      return 1
    }

    TMP_ARCHIVE="${FILE%.gpg}"

    echo "🔓 Decrypting..."
    gpg --batch --yes --passphrase "$PWDM" \
        --output "$TMP_ARCHIVE" \
        --decrypt "$FILE" || {
      echo "Decryption failed"
      return 1
    }

    FILE="$TMP_ARCHIVE"
  fi

  echo "📦 Extracting..."
  tar -xzf "$FILE" || {
    echo "Extraction failed"
    return 1
  }

  echo "✔ Done"

  # Optional: cleanup temp decrypted file
  if [[ -n "$TMP_ARCHIVE" && -f "$TMP_ARCHIVE" ]]; then
    rm -f "$TMP_ARCHIVE"
    echo "🧹 Cleaned temporary file"
  fi
}

extract_tar1() {
  [[ -z "$1" ]] && { echo "Usage: extract_tar <archive>"; return 1; }
  tar -xzf "$1"
}


### ────────────────────────────
### 🔒 Create Backup Archive

create_backup_gpg() {
  [[ -z "$1" ]] && { echo "Usage: tg <directory>"; return 1; }

  # Step 1: create backup
  create_backup "$1" || return 1

  # Step 2: find latest archive for this directory
  local TARGET DIR_NAME LATEST ARCHIVE_GPG

  TARGET=$(realpath "$1" 2>/dev/null) || return 1
  DIR_NAME=$(basename "$TARGET")

  LATEST=$(ls -t "$BACKUP"/${DIR_NAME}_*.tar.gz 2>/dev/null | head -n1)

  [[ -z "$LATEST" ]] && {
    echo "No archive found to encrypt"
    return 1
  }

  [[ -z "$PWDM" ]] && {
    echo "PWDM env variable not set"
    return 1
  }

  ARCHIVE_GPG="${LATEST}.gpg"

  # Step 3: encrypt
  gpg --batch --yes --passphrase "$PWDM" \
      --symmetric --cipher-algo AES256 \
      -o "$ARCHIVE_GPG" "$LATEST" || {
    echo "Encryption failed"
    return 1
  }

  # Step 4: delete original ONLY if encryption succeeded
  rm -f -- "$LATEST"

  echo "🔐 Encrypted:"
  echo "  $ARCHIVE_GPG"
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
