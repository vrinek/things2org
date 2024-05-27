#!/usr/bin/env fish

set start_index 0

if test -z $history_key
    exit 1
end

set latest_server_index (
    http https://cloud.culturedcode.com/version/1/history/$history_key \
        | jq -r '."latest-server-index"'
)

echo "Latest server index: $latest_server_index"

set items_url "https://cloud.culturedcode.com/version/1/history/"$history_key"/items"

while test $start_index -lt $latest_server_index
    echo "Fetching items from $start_index"
    http $items_url start-index==$start_index > items.$start_index.json
    set items_count (jq -r '.items | length' items.$start_index.json)
    echo "Fetched $items_count items"

    set start_index (math $start_index + $items_count)
end
