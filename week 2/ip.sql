WITH unnest_exclusions AS (
    SELECT
        unique_id, 
        order_id, 
        UNNEST(STRING_TO_ARRAY(exclusions, ',')) AS exclusions
    FROM  clean_customer_orders
    )

SELECT 
    unes.*, 
    pt.topping_name
INTO exclusions_table
    FROM unnest_exclusions unes 
    JOIN pizza_toppings pt
    ON unes.exclusions::integer = pt.topping_id


WITH unnest_extras AS (
    SELECT
        unique_id, 
        order_id, 
        UNNEST(STRING_TO_ARRAY(extras, ',')) AS extras
    FROM  clean_customer_orders
    )

SELECT 
    unex.*, 
    pt.topping_name
INTO extras_table
    FROM unnest_extras unex 
    JOIN pizza_toppings pt
    ON unex.extras::integer = pt.topping_id;


WITH extras_and_exclusions AS
(
    SELECT 
        unique_id, 
        order_id, 
        STRING_AGG(topping_name::varchar, ', ') AS topping_name
    FROM 
        (SELECT 
            unique_id, 
            order_id, 
            CONCAT('Exclude - ', STRING_AGG(topping_name::varchar, ', ')) AS topping_name 
        FROM exclusions_table
        GROUP BY unique_id, order_id
        
        UNION
        
        SELECT 
            unique_id, 
            order_id, 
            CONCAT('Extra - ', STRING_AGG(topping_name::varchar, ', ')) AS topping_name 
        FROM extras_table
        GROUP BY unique_id, order_id) AS combined
    GROUP BY unique_id, order_id)

SELECT 
    co.*, 
    CASE WHEN co.exclusions IS NULL AND co.extras IS NULL THEN pn.pizza_name 
    ELSE CONCAT(pn.pizza_name, ' - ', ee.topping_name) END AS order_item 
FROM clean_customer_orders co
    JOIN pizza_names pn
    ON co.pizza_id = pn.pizza_id
    LEFT JOIN extras_and_exclusions ee
    ON co.unique_id = ee.unique_id
ORDER BY co.order_id