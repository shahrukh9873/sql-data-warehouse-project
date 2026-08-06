/*
=====================================================
Stored Procedure: Load Bronze layer (Source -> Bronze)
=====================================================
Script Perpose:
    This stored procedure load the data into 'bronze' schema from the external csv files.
    It performs the following actions:
    - Truncates the bronze tables before loading the data.
    - Use the 'copy' command to load data from csv files to the bronze tables.
    - Maintances the Audit logging and Loading duration logs for each table and whole layer. 
Parameters:
    None.
        This store procedure doesn't accept any parameter or return any values.

Usage Example:
    Call bronze.load_bronze();
*/

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$
DECLARE
    batch_start_time  TIMESTAMP;
    batch_end_time  TIMESTAMP;
    start_time  TIMESTAMP;
    end_time  TIMESTAMP;
    v_rows BIGINT;
BEGIN
    batch_start_time:= clock_timestamp();

    RAISE NOTICE '===========================================';
    RAISE NOTICE 'Loading: Bronze Layer...';
    RAISE NOTICE '===========================================';

    ----------------------------------------------------------
    --CRM Tables
    ----------------------------------------------------------

    RAISE NOTICE 'Loading: CRM tables..';

    ------------------- crm_cust_info -----------------------
    start_time:= clock_timestamp();

    RAISE NOTICE 'Truncating: bronze.crm_cust_info';

    TRUNCATE TABLE bronze.crm_cust_info;

    RAISE NOTICE 'Inserting Data into bronze.crm_cust_info';

    COPY bronze.crm_cust_info
    FROM '/var/lib/postgresql/import/source_crm/cust_info.csv'
    DELIMITER ','
    CSV HEADER;

-- Audit logging of Loaded Rows count

    SELECT COUNT(*)
    INTO v_rows
    FROM bronze.crm_cust_info;

    RAISE NOTICE 'Loaded Rows: %', v_rows;

    end_time:= clock_timestamp();

    RAISE NOTICE 'Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

    ------------------- crm_prd_info -----------------------
    start_time:= clock_timestamp();

    RAISE NOTICE 'Truncating: bronze.crm_prd_info';

    TRUNCATE TABLE bronze.crm_prd_info;

    RAISE NOTICE 'Inserting Data into bronze.crm_prd_info';

    COPY bronze.crm_prd_info
    FROM '/var/lib/postgresql/import/source_crm/prd_info.csv'
    DELIMITER ','
    CSV HEADER;

-- Audit logging of Loaded Rows count

    SELECT COUNT(*)
    INTO v_rows
    FROM bronze.crm_prd_info;

    RAISE NOTICE 'Loaded Rows: %', v_rows;

    end_time:= clock_timestamp();

    RAISE NOTICE 'Load Duration: % seconds'
        ,EXTRACT(EPOCH FROM (end_time - start_time));

    ------------------- crm_sales_details -----------------------
    start_time:= clock_timestamp();

    RAISE NOTICE 'Truncating: bronze.crm_sales_details';

    TRUNCATE TABLE bronze.crm_sales_details;

    RAISE NOTICE 'Inserting Data into bronze.crm_sales_details';

    COPY bronze.crm_sales_details
    FROM '/var/lib/postgresql/import/source_crm/sales_details.csv'
    DELIMITER ','
    CSV HEADER;

    -- Audit logging of Loaded Rows count

    SELECT COUNT(*)
    INTO v_rows
    FROM bronze.crm_sales_details;

    RAISE NOTICE 'Loaded Rows: %', v_rows;

    end_time:= clock_timestamp();

    RAISE NOTICE 'Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

    ----------------------------------------------------------
    --ERP Tables
    ----------------------------------------------------------

    RAISE NOTICE 'Loading: ERP tables..';

    ------------------- erp_cust_az12 -----------------------
    start_time:= clock_timestamp();

    RAISE NOTICE 'Truncating: bronze.erp_cust_az12';

    TRUNCATE TABLE bronze.erp_cust_az12;

    RAISE NOTICE 'Inserting Data Into bronze.erp_cust_az12';

    COPY bronze.erp_cust_az12
    FROM '/var/lib/postgresql/import/source_erp/CUST_AZ12.csv'
    DELIMITER ','
    CSV HEADER;

-- Audit logging of Loaded Rows count

    SELECT COUNT(*)
    INTO v_rows
    FROM bronze.erp_cust_az12;

    RAISE NOTICE 'Loaded Rows: %', v_rows;

    end_time:= clock_timestamp();

    RAISE NOTICE 'Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

    ------------------- erp_loc_a101 -----------------------
    start_time:= clock_timestamp();

    RAISE NOTICE 'Truncating: bronze.erp_loc_a101';

    TRUNCATE TABLE bronze.erp_loc_a101;

    RAISE NOTICE 'Inserting Data into erp_loc_a101';

    COPY bronze.erp_loc_a101
    FROM '/var/lib/postgresql/import/source_erp/LOC_A101.csv'
    DELIMITER ','
    CSV HEADER;

    -- Audit logging of Loaded Rows count

    SELECT COUNT(*)
    INTO v_rows
    FROM bronze.erp_loc_a101;

    RAISE NOTICE 'Loaded Rows: %', v_rows;

    end_time:= clock_timestamp();

    RAISE NOTICE 'Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

    ------------------- erp_px_cat_g1v2 -----------------------
    start_time:= clock_timestamp();

    RAISE NOTICE 'Truncating: bronze.erp_px_cat_g1v2';

    TRUNCATE TABLE bronze.erp_px_cat_g1v2;

    RAISE NOTICE 'Inserting data into bronze.erp_px_cat_g1v2';

    COPY bronze.erp_px_cat_g1v2
    FROM '/var/lib/postgresql/import/source_erp/PX_CAT_G1V2.csv'
    DELIMITER ','
    CSV HEADER;

    -- Audit logging of Loaded Rows count

    SELECT COUNT(*)
    INTO v_rows
    FROM bronze.erp_px_cat_g1v2;

    RAISE NOTICE 'Loaded Rows: %', v_rows;

    end_time:= clock_timestamp();

    RAISE NOTICE 'Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

    -----------------------------------------------------------
    batch_end_time:= clock_timestamp();

    RAISE NOTICE '=============================================';
    RAISE NOTICE 'Bronze Layer is completed successfully';
    RAISE NOTICE 'Total Load Duration: % seconds',
        EXTRACT(EPOCH FROM (batch_end_time - batch_start_time));
    RAISE NOTICE '=============================================';

EXCEPTION
    WHEN OTHERS THEN
        RAISE '=======================================';
        RAISE 'ERROR OCCURRED DURING BRONZE LOAD';
        RAISE 'SQLSTATE: % ',SQLSTATE;
        RAISE 'ERROR MESSAGE: %',SQLERRM;
        RAISE '=======================================';
END;
$$;
