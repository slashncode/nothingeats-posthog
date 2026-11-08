-- Every order's total in euros: what customers did not spend by ordering nothing.
SELECT round(sum(toFloat(properties.money_not_spent_cents)) / 100, 2) AS euros_not_spent
FROM events
WHERE event = 'order_placed'
