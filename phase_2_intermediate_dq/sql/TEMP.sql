USE DATABASE DQ_INTERMEDIATE_LAB;


USE SCHEMA LOOKUPS;

    SELECT 
        ROW_ID,
        CUSTOMER_NAME,
        ORDER_ID,
        'NULL_CHECK',
        'CUSTOMER_NAME',
        'NULL',
        'Customer Name is required and cannot be empty',
        'ERROR',
        OBJECT_CONSTRUCT(
            'CUSTOMER_NAME', CUSTOMER_NAME, 'EMAIL', EMAIL,
            'ORDER_ID', ORDER_ID, 'ORDER_AMOUNT', ORDER_AMOUNT
        )
    FROM RAW.CUSTOMER_ORDERS
    WHERE CUSTOMER_NAME IS NULL;