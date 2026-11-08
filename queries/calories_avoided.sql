-- The calories of every dish ordered and never delivered.
SELECT sum(toInt(properties.calories_avoided)) AS calories_not_eaten
FROM events
WHERE event = 'order_placed'
