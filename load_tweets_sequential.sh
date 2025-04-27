#!/usr/bin/env bash
set -euo pipefail

# find all .zip files once
files=(data/*.zip)

echo '================================================================================'
echo 'load denormalized'
echo '================================================================================'
time for file in "${files[@]}"; do
    echo "→ loading ${file##*/} into denormalized…"
    unzip -p "$file" \
      | sed 's/\\u0000//g' \
      | psql "postgres://postgres:pass@localhost:4535/twitter" \
            -c "COPY tweets_jsonb(data)
                 FROM STDIN
                 CSV
                 QUOTE E'\x01'
                 DELIMITER E'\x02';"
done

echo '================================================================================'
echo 'load pg_normalized'
echo '================================================================================'
time for file in "${files[@]}"; do
    echo "→ normalizing ${file##*/}…"
    python3 load_tweets.py \
      --db "postgresql://postgres:pass@localhost:4536/twitter" \
      --inputs "$file"
done

echo '================================================================================'
echo 'load pg_normalized_batch'
echo '================================================================================'
time for file in "${files[@]}"; do
    echo "→ batch-inserting ${file##*/}…"
    python3 -u load_tweets_batch.py \
      --db "postgresql://postgres:pass@localhost:4537/twitter" \
      --inputs "$file"
done

