-- Queries (lowercased by search-service) that found no dish, most frequent first.
SELECT
    properties.query AS query,
    count() AS searches,
    count(DISTINCT person_id) AS people,
    max(timestamp) AS last_searched
FROM events
WHERE event = 'search_performed'
    AND toInt(properties.results) = 0
    AND timestamp > now() - INTERVAL 30 DAY
GROUP BY query
ORDER BY searches DESC
LIMIT 20
