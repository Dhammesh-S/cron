#!/data/data/com.termux/files/usr/bin/bash

# AEGIS STEPWISE REFACTOR ORCHESTRATOR
# ---------------------
# Usage:
# bash refactor_one.sh 15  → waits 15 sec between LLM calls (rate control)
# Can be scheduled by CRON or run interactively.

# Set time delay from CLI or default to 30 seconds
TIME_DELAY=${1:-30}

# Directories (adjust if customized)
PROJECT_DIR="$HOME/trading_ai_project"
INPUT_DIR="$PROJECT_DIR/broker_input"
MODULES_DIR="$PROJECT_DIR/modules"
LOG_DIR="$PROJECT_DIR/logs"

# Ensure folders exist
mkdir -p "$MODULES_DIR" "$LOG_DIR"

# Define Python command for Aegis
AEGIS="$HOME/AI_GODS/aegis.py"

# Loop through one file at a time in broker_input
echo "[START] Running Aegis stepwise fix at $(date)"

for file in $(find "$INPUT_DIR" -type f -name "*.py" | sort); do
    # Only act on one file with issues
    echo "[INFO] Processing: $file"
    
    # Run aegis in stepwise (one-fix-per-file mode)
    python3 "$AEGIS" \
        --input "$file" \
        --output "$MODULES_DIR" \
        --mode stepwise \
        --log "$LOG_DIR/aegis_$(basename "$file").log"

    echo "[INFO] Sleeping for $TIME_DELAY seconds..."
    sleep "$TIME_DELAY"

    # Proceed to Git commit right after this one fix
    cd "$PROJECT_DIR"
    git add .
    git commit -m "Aegis one-fix refactor: $(basename "$file") [$(date +'%Y-%m-%d %H:%M:%S')]" 2>/dev/null || echo "[INFO] Nothing new to commit"
    git push origin main   # You can set to 'autobot' branch if preferred

    echo "[DONE] One-step refactor and Git commit completed."
    exit 0  # Exit after fixing one file
done

echo "[INFO] No .py files left for stepwise refactor in broker_input"
