{pkgs, ...}:
pkgs.writeShellScriptBin "note" ''

  # Colors for nice output
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  MAGENTA='\033[0;35m'
  CYAN='\033[0;36m'
  WHITE='\033[1;37m'
  GRAY='\033[0;37m'
  BOLD='\033[1m'
  NC='\033[0m' # No Color

  # XDG-compliant notes directory and file
  NOTES_DIR="$HOME/.local/share/notes"
  NOTES_FILE="$NOTES_DIR/notes.txt"

  # Create notes directory if it doesn't exist
  mkdir -p "$NOTES_DIR"

  # Function to display usage
  show_usage() {
    echo -e "''${BOLD}''${BLUE}📝 Note Manager''${NC}"
    echo -e "''${GRAY}Usage:''${NC}"
    echo -e "  ''${CYAN}note''${NC} ''${YELLOW}<text>''${NC}                 - Add a new note"
    echo -e "  ''${CYAN}note''${NC}                       - Display all notes"
    echo -e "  ''${CYAN}note del''${NC} ''${YELLOW}<number>''${NC}          - Delete note by number"
    echo -e "  ''${CYAN}note clear''${NC}                 - Clear all notes"
    echo -e "  ''${CYAN}echo 'text' | note''${NC}        - Add note from stdin"
    echo -e "  ''${CYAN}cat file | note''${NC}           - Add file contents as note"
    echo ""
    echo -e "''${GRAY}Examples:''${NC}"
    echo -e "  ''${GREEN}note call plumber tomorrow''${NC}"
    echo -e "  ''${GREEN}cat todo.txt | note''${NC}"
    echo -e "  ''${GREEN}note del 3''${NC}"
  }

  # Function to add a note
  add_note() {
    local note_text="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local date_only=$(date '+%Y-%m-%d')

    # Create notes file if it doesn't exist
    touch "$NOTES_FILE"

    # Get next note number
    local note_num=1
    if [ -f "$NOTES_FILE" ] && [ -s "$NOTES_FILE" ]; then
      note_num=$(grep -E "^#[0-9]+" "$NOTES_FILE" | sed 's/^#\([0-9]*\).*/\1/' | sort -n | tail -1)
      note_num=$((note_num + 1))
    fi

    # Add the note with proper formatting
    {
      echo "#$note_num [$timestamp]"
      echo "$note_text"
      echo ""
    } >> "$NOTES_FILE"

    echo -e "''${GREEN}✓''${NC} Note #$note_num added ''${GRAY}($date_only)''${NC}"
  }

  # Function to display all notes
  display_notes() {
    if [ ! -f "$NOTES_FILE" ] || [ ! -s "$NOTES_FILE" ]; then
      echo -e "''${YELLOW}📝 No notes found''${NC}"
      echo -e "''${GRAY}Use ''${CYAN}note <text>''${GRAY} to add your first note''${NC}"
      return
    fi

    echo -e "''${BOLD}''${BLUE}📝 Your Notes''${NC}"
    echo -e "''${GRAY}📁 $NOTES_FILE''${NC}"
    echo -e "''${GRAY}$(printf '%.0s─' {1..50})''${NC}"

    local in_note=false
    local note_content=""

    while IFS= read -r line; do
      # Check if line starts with # followed by numbers and space and [
      if echo "$line" | grep -q "^#[0-9][0-9]* \["; then
        # Print previous note content if exists
        if [ "$in_note" = true ] && [ -n "$note_content" ]; then
          echo -e "$note_content"
          echo ""
        fi

        # Extract note number and timestamp
        local num=$(echo "$line" | sed 's/^#\([0-9]*\) \[.*/\1/')
        local timestamp=$(echo "$line" | sed 's/^#[0-9]* \[\(.*\)\]/\1/')
        local date_part=$(echo "$timestamp" | cut -d' ' -f1)
        local time_part=$(echo "$timestamp" | cut -d' ' -f2)

        echo -e "''${BOLD}''${CYAN}#$num''${NC} ''${GRAY}[$date_part ''${YELLOW}$time_part''${GRAY}]''${NC}"
        in_note=true
        note_content=""
      elif [ -n "$line" ] && [ "$in_note" = true ]; then
        # Accumulate note content
        if [ -z "$note_content" ]; then
          note_content="''${WHITE}$line''${NC}"
        else
          note_content="$note_content\n''${WHITE}$line''${NC}"
        fi
      elif [ -z "$line" ] && [ "$in_note" = true ]; then
        # End of current note
        if [ -n "$note_content" ]; then
          echo -e "$note_content"
          echo ""
        fi
        in_note=false
        note_content=""
      fi
    done < "$NOTES_FILE"

    # Print last note if file doesn't end with empty line
    if [ "$in_note" = true ] && [ -n "$note_content" ]; then
      echo -e "$note_content"
      echo ""
    fi

    local total_notes=$(grep -c "^#[0-9]" "$NOTES_FILE")
    echo -e "''${GRAY}$(printf '%.0s─' {1..50})''${NC}"
    echo -e "''${GRAY}Total: ''${BOLD}$total_notes''${NC} ''${GRAY}notes''${NC}"
  }

  # Function to delete a note
  delete_note() {
    local note_num="$1"

    if [ ! -f "$NOTES_FILE" ] || [ ! -s "$NOTES_FILE" ]; then
      echo -e "''${RED}✗''${NC} No notes found"
      return 1
    fi

    if ! echo "$note_num" | grep -q "^[0-9][0-9]*$"; then
      echo -e "''${RED}✗''${NC} Invalid note number: $note_num"
      return 1
    fi

    # Check if note exists
    if ! grep -q "^#$note_num " "$NOTES_FILE"; then
      echo -e "''${RED}✗''${NC} Note #$note_num not found"
      return 1
    fi

    # Create temporary file without the specified note
    local temp_file=$(mktemp)
    local skip_lines=false

    while IFS= read -r line; do
      if echo "$line" | grep -q "^#[0-9][0-9]* "; then
        local current_num=$(echo "$line" | sed 's/^#\([0-9]*\) .*/\1/')
        if [ "$current_num" = "$note_num" ]; then
          skip_lines=true
          continue
        else
          skip_lines=false
        fi
      fi

      if [ "$skip_lines" = false ]; then
        echo "$line" >> "$temp_file"
      elif [ -z "$line" ]; then
        # Stop skipping when we hit an empty line (end of note)
        skip_lines=false
      fi
    done < "$NOTES_FILE"

    mv "$temp_file" "$NOTES_FILE"
    echo -e "''${GREEN}✓''${NC} Note #$note_num deleted"
  }

  # Function to clear all notes
  clear_notes() {
    if [ ! -f "$NOTES_FILE" ] || [ ! -s "$NOTES_FILE" ]; then
      echo -e "''${YELLOW}📝 No notes to clear''${NC}"
      return
    fi

    local total_notes=$(grep -c "^#[0-9]" "$NOTES_FILE")
    echo -e "''${YELLOW}⚠''${NC}  This will delete all $total_notes notes. Are you sure? ''${GRAY}[y/N]''${NC}"
    read -r confirmation

    if echo "$confirmation" | grep -qi "^y"; then
      > "$NOTES_FILE"
      echo -e "''${GREEN}✓''${NC} All notes cleared"
    else
      echo -e "''${BLUE}ℹ''${NC}  Operation cancelled"
    fi
  }

  # Main script logic
  main() {
    # Check if input is being piped
    if [ ! -t 0 ]; then
      # Read from stdin (pipe)
      local piped_content=""
      while IFS= read -r line; do
        if [ -z "$piped_content" ]; then
          piped_content="$line"
        else
          piped_content="$piped_content"$'\n'"$line"
        fi
      done

      if [ -n "$piped_content" ]; then
        add_note "$piped_content"
      else
        echo -e "''${RED}✗''${NC} No input received from pipe"
        exit 1
      fi
      return
    fi

    # Handle command line arguments
    case "$1" in
      "")
        display_notes
        ;;
      "del")
        if [ -z "$2" ]; then
          echo -e "''${RED}✗''${NC} Please specify note number to delete"
          echo -e "''${GRAY}Usage: ''${CYAN}note del <number>''${NC}"
          exit 1
        fi
        delete_note "$2"
        ;;
      "clear")
        clear_notes
        ;;
      "help"|"--help"|"-h")
        show_usage
        ;;
      *)
        # Everything else is treated as note content
        add_note "$*"
        ;;
    esac
  }

  main "$@"
''
