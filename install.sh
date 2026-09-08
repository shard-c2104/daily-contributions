#!/bin/bash
set -e

echo -e "\033[1;36m🟢 Installing GitHub Contribution Painter...\033[0m"

curl -sSL https://raw.githubusercontent.com/shard-c2104/daily-contributions/main/contribute.sh -o /usr/local/bin/contribute
chmod +x /usr/local/bin/contribute

echo -e "\033[1;32m✅ Successfully installed 'contribute' to /usr/local/bin/contribute!\033[0m"
echo -e "You can now run \033[1mcontribute\033[0m from anywhere."
echo ""
echo "Try: contribute --help"
