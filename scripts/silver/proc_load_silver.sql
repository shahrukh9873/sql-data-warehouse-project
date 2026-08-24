/*
=================================================================
Stored Procedure: Load silver layer (Bronze -> Silver)
=================================================================
Scripts Purpose:
    This load procedure performs ETL (Extract Transform Load) to populate
    the silver schema table from the bronze schema.
        Action performed:
            - Truncates silver tables.
            - insert transformed and cleaned data from bronze into silver
    Parameter:
        none.
            This procedure doesn't have any parameter or return any value
Usage Example:
    call silver.load_silver();
*/

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE
    start_time  TIMESTAMP;
    end_time  TIMESTAMP;
    batch_start_time  TIMESTAMP;
    batch_end_time  TIMESTAMP;
    v_rows BIGINT;
BEGIN
    batch_start_time:= CLOCK_TIMESTAMP();

    RAISE NOTICE '=============================================';
    RAISE NOTICE 'Loading Silver Layer...';
    RAISE NOTICE '=============================================';

    ----------------------------------------------------------
    --CRM Tables
    ----------------------------------------------------------


    RAISE NOTICE '---------------------------------------------';
    RAISE NOTICE 'Loading CRM TABLES..';
    RAISE NOTICE '---------------------------------------------';

    RAISE NOTICE '------------------- crm_cust_info -----------------------';

    start_time:= CLOCK_TIMESTAMP();

    RAISE NOTICE 'Truncating Table: silver.crm_cust_info';
    TRUNCATE TABLE silver.crm_cust_info;

    RAISE NOTICE 'Inserting Table: silver.crm_cust_info';
    INSERT INTO silver.crm_cust_info(
        cst_id,
        cst_key,
        cst_lastname,
        cst_firstname,
        cst_marital_status,
        cst_gndr,
        cst_create_date
    )
    SELECT 
        cst_id,
        cst_key,
        UPPER(TRIM(cst_firstname)) AS cst_firstname,
        UPPER(TRIM(cst_lastname)) AS cst_lastname,
        CASE
            WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
            WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
            ELSE 'n/a'
        END AS cst_marital_status,
        CASE
            WHEN cst_gndr = 'M' THEN 'Male'
            WHEN cst_gndr = 'F' THEN 'Female'
            ELSE 'n/a'
        END AS cst_gndr,
        cst_create_date
    FROM
        (SELECT *,
            ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
    )t WHERE flag_last = 1;

 -- Audit logging of Loaded Rows count

    SELECT COUNT(*)
    INTO v_rows
    FROM silver.crm_cust_info;

    RAISE NOTICE 'Loaded Rows: % Records',v_rows;


    end_time:= CLOCK_TIMESTAMP();

    RAISE NOTICE 'Load Duration: % seconds',
        EXTRACT(EPOCH FROM(end_time - start_time));

    RAISE NOTICE '------------------- crm_prd_info -----------------------';

    start_time:= CLOCK_TIMESTAMP();

    RAISE NOTICE 'Truncating Table silver.crm_prd_info';
    TRUNCATE TABLE silver.crm_prd_info; 

    RAISE NOTICE 'Inserting silver.crm_prd_info..';
    INSERT INTO silver.crm_prd_info(
        prd_id,
        prd_key,
        cat_id,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )

    SELECT 
        prd_id,
        SUBSTRING(prd_key,5, LENGTH(prd_key)) AS prd_key,
        REPLACE(SUBSTRING(prd_key,1,5), '-', '_') AS cat_id,
        prd_nm,
        CASE
            WHEN prd_cost IS NULL THEN 0
            ELSE prd_cost 
        END AS prd_cost,
        CASE
            WHEN UPPER(TRIM(prd_line)) ='M' THEN 'Mountain'
            WHEN UPPER(TRIM(prd_line)) ='R' THEN 'Road'
            WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
            ELSE 'n/a'
        END AS prd_line,
        prd_start_dt,
        CAST(LEAD(prd_start_dt)
                OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt
    FROM bronze.crm_prd_info;

 -- Audit logging of Loaded Rows count


    SELECT COUNT(*)
    INTO v_rows
    FROM silver.crm_prd_info;

    RAISE NOTICE 'Loaded Rows: % Records', v_rows;

    end_time:= CLOCK_TIMESTAMP();

    RAISE NOTICE 'Load Duration: % Seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

    RAISE NOTICE '------------------- crm_sales_details -----------------------';

    start_time:= CLOCK_TIMESTAMP();

    RAISE NOTICE 'Truncating Table: silver.crm_sales_details';
    TRUNCATE TABLE silver.crm_sales_details;

    RAISE NOTICE 'Inserting Table: silver.crm_sales_details..';
    INSERT INTO silver.crm_sales_details(
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantity,
        sls_price
    )
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        CAST(CAST(CASE
                WHEN sls_order_dt <=0 
                OR LENGTH(CAST(sls_order_dt AS VARCHAR))>8 
                OR sls_order_dt > 20250101 
                OR sls_order_dt < 19900101 THEN NULL
                ELSE sls_order_dt 
            END AS VARCHAR )AS DATE )AS sls_order_dt,
        CAST(CAST(CASE
                WHEN sls_ship_dt <=0 
                OR LENGTH(CAST(sls_ship_dt AS VARCHAR))>8 
                OR sls_ship_dt > 20250101 
                OR sls_ship_dt < 19900101 THEN NULL
                ELSE sls_ship_dt 
            END AS VARCHAR )AS DATE )AS sls_ship_dt,
        CAST(CAST(CASE
                WHEN sls_due_dt <=0 
                OR LENGTH(CAST(sls_due_dt AS VARCHAR))>8 
                OR sls_due_dt > 20250101 
                OR sls_due_dt < 19900101 THEN NULL
                ELSE sls_due_dt 
            END AS VARCHAR )AS DATE )AS sls_due_dt,
        CASE
            WHEN sls_sales IS NULL
                OR sls_sales <=0
                OR sls_sales != (sls_quantity * sls_price) 
                THEN (sls_quantity * ABS(sls_price))
            ELSE sls_sales
        END AS sls_sales,
        sls_quantity,
        CASE
            WHEN sls_price IS NULL OR sls_price <=0
            THEN (sls_sales / sls_quantity)
            ELSE sls_price
        END AS sls_price
    FROM bronze.crm_sales_details;

 -- Audit logging of Loaded Rows count


    SELECT COUNT(*)
    INTO v_rows
    FROM silver.crm_sales_details;

    RAISE NOTICE 'Loaded Rows: % Records',v_rows;

    end_time:= CLOCK_TIMESTAMP();
    
    RAISE NOTICE 'Load Duration: % Seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));
    ----------------------------------------------------------
    --ERP Tables
    ----------------------------------------------------------

    RAISE NOTICE '---------------------------------------------';
    RAISE NOTICE 'Loading ERP TABLES..';
    RAISE NOTICE '---------------------------------------------';

    RAISE NOTICE '------------------- erp_cust_az12 -----------------------';
    start_time:= CLOCK_TIMESTAMP();

    RAISE NOTICE 'Truncating Table: silver.erp_cust_az12';
    TRUNCATE TABLE silver.erp_cust_az12;

    RAISE NOTICE 'Inserting Table: silver.erp_cust_az12';
    INSERT INTO silver.erp_cust_az12(
        cid,
        bdate,
        gen
    )
    SELECT
        CASE
            WHEN cid LIKE 'NAS%' 
            THEN SUBSTRING(cid,4,LENGTH(cid))
            ELSE cid
        END AS cid,
        CASE
            WHEN CAST(bdate AS DATE) > CURRENT_DATE THEN NULL
            ELSE CAST(bdate AS DATE)
        END AS bdate,
        CASE
            WHEN UPPER(TRIM(gen)) = 'M' THEN 'Male'
            WHEN UPPER(TRIM(gen)) = 'F' THEN 'Female'
            ELSE 'n/a'
        END AS gen
    FROM bronze.erp_cust_az12;

 -- Audit logging of Loaded Rows count


    SELECT COUNT(*)
    INTO v_rows
    FROM silver.erp_cust_az12;

    RAISE NOTICE 'Loaded Rows: % Records', v_rows;

    end_time:= CLOCK_TIMESTAMP();

    RAISE NOTICE 'Load Duration: % Seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

    RAISE NOTICE '------------------- erp_loc_a101 -----------------------';

    start_time:= CLOCK_TIMESTAMP();

    RAISE NOTICE 'Truncating Table: silver.erp_loc_a101';
    TRUNCATE TABLE silver.erp_loc_a101;

    RAISE NOTICE 'Inserting Table: silver.erp_loc_a101';
    INSERT INTO silver.erp_loc_a101(
        cid,
        cntry
    )
    SELECT
        REPLACE(cid,'-','') AS cid,
        CASE
            WHEN UPPER(TRIM(cntry)) = 'DE'THEN 'Germany'
            WHEN UPPER(TRIM(cntry)) IN ('US','USA') THEN 'United states'
            WHEN UPPER(TRIM(cntry)) = '' OR cntry IS NULL THEN 'n/a'
            ELSE cntry
        END AS cntry
    FROM bronze.erp_loc_a101;

 -- Audit logging of Loaded Rows count

    SELECT COUNT(*)
    INTO v_rows
    FROM silver.erp_loc_a101;

    RAISE NOTICE 'Loaded Rows: % Records', v_rows;

    
    end_time:= CLOCK_TIMESTAMP();

    RAISE NOTICE 'Load Duration: % Seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

    RAISE NOTICE '------------------- erp_px_cat_g1v2 -----------------------';
    start_time:= CLOCK_TIMESTAMP();

    RAISE NOTICE 'Truncating Table: silver.erp_px_cat_g1v2';
    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    RAISE NOTICE 'Inserting Table: silver.erp_px_cat_g1v2';
    INSERT INTO silver.erp_px_cat_g1v2(
        id,
        cat,
        subcat,
        maintenance
    )
    SELECT
        id,
        cat,
        subcat,
        maintenance
    FROM bronze.erp_px_cat_g1v2;

 -- Audit logging of Loaded Rows count

    SELECT COUNT(*)
    INTO v_rows
    FROM silver.erp_px_cat_g1v2;

    RAISE NOTICE 'Loaded Rows: % Records', v_rows;

    end_time:= CLOCK_TIMESTAMP();

    RAISE NOTICE 'Load Duration: % Seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

    ---------------------------------------------
    batch_end_time:= CLOCK_TIMESTAMP();
    RAISE NOTICE '=============================================';
    RAISE NOTICE 'Silver Layer is Completed Successfully';
    RAISE NOTICE 'Total Load Duration: % seconds',
        EXTRACT(EPOCH FROM (batch_end_time - batch_start_time));
    RAISE NOTICE '=============================================';

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '===================================';
            RAISE NOTICE 'Error Occured During Silver load';
            RAISE NOTICE 'SQL Statement: %', SQLSTATE;
            RAISE NOTICE 'Error Message:%', SQLERRM;
            RAISE NOTICE '===================================';
END;
$$;

