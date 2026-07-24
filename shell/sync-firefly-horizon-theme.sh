#!/usr/bin/env bash
set -euo pipefail

CONTAINER="${DISCOURSE_CONTAINER:-discourse_dev}"
THEME_NAME="${FIREFLY_THEME_NAME:-Firefly-Horizon}"
THEME_PATH="${FIREFLY_THEME_PATH:-/src/themes/firefly-horizon}"

docker exec \
  -e FIREFLY_THEME_NAME="$THEME_NAME" \
  -e FIREFLY_THEME_PATH="$THEME_PATH" \
  -i "$CONTAINER" \
  bash -lc "cat > /tmp/sync_firefly_theme.rb && cd /src && runuser -u discourse -- /bin/bash -lc 'bin/rails runner /tmp/sync_firefly_theme.rb'" <<'RUBY'
path = ENV.fetch("FIREFLY_THEME_PATH")
name = ENV.fetch("FIREFLY_THEME_NAME")
existing = Theme.find_by(name: name)
theme = RemoteTheme.import_theme_from_directory(path, theme_id: existing&.id)
theme.update!(enabled: true, user_selectable: true)
theme.set_default!
puts "synced #{theme.name} ##{theme.id}"
RUBY
