set -e

if [ -z ${PATH_PREFIX+x} ]; then
    echo "\$PATH_PREFIX is not set, exiting."
    exit
fi

if [ -z "$SEARCH_SECRET" ]; then
    echo "\$SEARCH_SECRET is not set or empty, exiting."
    exit
fi

if [ -z "$LANGS" ]; then
    echo "\$LANGS is not set or empty, exiting."
    exit
fi

echo "Port knocking"
# This returns error code 28 (timeout), which is fine. 
curl --silent --connect-timeout 1 standard.open-contracting.org:8255 || true

echo "Copy the built files to the remote server..."
rsync -avz --delete-after build/ ocds-docs@standard.open-contracting.org:web/staging/$PATH_PREFIX${GITHUB_REF##*/}

echo "Update the search index..."
curl -sS --fail "https://standard-search.open-contracting.org/v1/index_ocds?secret=${SEARCH_SECRET}&version=$(echo staging/$PATH_PREFIX | sed 's/\//%2F/g')${GITHUB_REF##*/}&langs=${LANGS}"
