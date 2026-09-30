/* 
======================================================================================================
Stored Procedure: Load Silver Layer (Bronze -> silver)
======================================================================================================
Script Purpose:
  This stored procedure performs the ETL(Extract, Transform , Load) process to 
  populate the 'silver' schema tables from the 'bronze' schema.
Actions Performed:
  -Truncates silver tables.
  -Inserts transformed and cleansed data from Bronze into silver tables.
Parameters :
  None
  This stored procedure does not accept any parameter or return any values.
Usage Example :
  EXEC silver.load_silver'
*/

CREATE OR ALTER PROCEDURE silver.load_silver as
BEGIN
	BEGIN TRY
		DECLARE 
			@start_time DATETIME,
			@end_time DATETIME,
			@batch_start_time DATETIME, 
			@batch_end_time DATETIME
		SET @batch_start_time = GETDATE();
		PRINT '-------------------------------------------------------';
		PRINT 'Loading Silver Layer';
		PRINT '-------------------------------------------------------';

		Print '--------------------------------------------------------';
		PRINT 'Loading CRM Tables';
		Print '--------------------------------------------------------';

		set @start_time = GETDATE();
		--clean and load the cust_info table
		PRINT '>>Truncating Table : silver.crm_cust_info';
		Truncate table silver.crm_cust_info;
		PRINT '>>Inserting Data Into: silver.crm_cust_info';
		INSERT INTO silver.crm_cust_info(
			[cst_id],
			[cst_key],
			[cst_firstname],
			[cst_lastname],
			[cst_marital_status],
			[cst_gndr],
			[cst_create_date]
		)
		Select 
			[cst_id],
			[cst_key],
			TRIM([cst_firstname]) AS cst_firstname,
			TRIM([cst_lastname]) AS cst_lastname, -- remove unwanted spaces
			CASE 
				WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
				WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
				Else 'N/A'
			END cst_marital_status, --Normalize marital status values to readable format
			CASE 
				WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
				WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
				Else 'N/A'
			END cst_gndr, --Normalize gender values to readable format
			[cst_create_date]
		from (
			select *,
			ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
			from bronze.crm_cust_info
			where cst_id IS NOT NULL
		) t 
		where flag_last = 1 -- Select the most recent record per customer
		set @end_time = GETDATE();
		PRINT 'Loading Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) as NVARCHAR) + ' seconds';
		PRINT '>>-------------------------------------------------------------';
		
		--clean and load the prd_info table
		set @start_time = GETDATE();
		PRINT '>>Truncating Table : silver.crm_prd_info';
		Truncate table silver.crm_prd_info;
		PRINT '>>Inserting Data Into: silver.crm_prd_info';
		Insert into silver.crm_prd_info (
			[prd_id],
			[cat_id],
			[prd_key],
			[prd_nm],
			[prd_cost],
			[prd_line],
			[prd_start_dt],
			[prd_end_dt]
		)
		select 
			[prd_id],
			REPLACE(SUBSTRING(prd_key,1,5), '-','_') As cat_id,--replace the hypen with underscore because in px_cat table their is _ in cid.
			SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key, -- Extract produt key
			[prd_nm],
			ISNULL(prd_cost,0) as prd_cost,
			CASE 
				When UPPER(TRIM(prd_line)) = 'M' Then 'Mountain'
				When UPPER(TRIM(prd_line)) = 'R' Then 'Road'
				When UPPER(TRIM(prd_line)) = 'S' Then 'Other Sales'
				When UPPER(TRIM(prd_line)) = 'T' Then 'Touring'
				Else 'N/A'
			END as prd_line, -- Map product line codes to descriptive values , standardization and normalization
			CAST([prd_start_dt] as DATE) as prd_start_date,
			CAST(
				DATEADD(day,-1,LEAD(prd_start_dt) OVER(Partition by prd_key Order by prd_start_dt)) as DATE 
				) as prd_end_dt -- Calculate end date as one day before the next start date.
		from bronze.crm_prd_info
		set @end_time = GETDATE();
		PRINT 'Loading Duration'+CAST(DATEDIFF(second,@start_time,@end_time) as NVARCHAR)+'seconds';
		PRINT '>>---------------------------------------------------------------';
		--clean and load the sales_details table
		
		set @start_time= GETDATE();
		PRINT '>>Truncating Table : silver.crm_sales_details';
		Truncate table silver.crm_sales_details;
		PRINT '>>Inserting Data Into: silver.crm_sales_details';
		INSERT INTO silver.crm_sales_details(
			[sls_ord_num],
			[sls_prd_key],
			[sls_cust_id],
			[sls_order_dt],
			[sls_ship_dt],
			[sls_due_dt],
			[sls_sales],
			[sls_quantity],
			[sls_price]
		)
		select 
			[sls_ord_num],
			TRIM([sls_prd_key]) as sls_prd_key,
			[sls_cust_id],
			CASE 
				WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_order_dt AS VARCHAR) As DATE)
			END as sls_order_dt,
			CASE 
				WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_ship_dt AS VARCHAR) As DATE)
			END as sls_ship_dt,
			CASE 
				WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_due_dt AS VARCHAR) As DATE)
			END as sls_due_dt,
			CASE 
				When sls_sales <=0 OR sls_sales is NULL OR sls_sales != sls_quantity * ABS(sls_price) Then sls_quantity * ABS(sls_price)
				ELSE sls_sales
			END sls_sales,
			[sls_quantity],
			CASE	
				WHEN sls_price <=0 OR sls_price IS NULL THEN sls_sales / NULLIF(sls_quantity,0)
				ELSE sls_price
			END as [sls_price]
		from bronze.crm_sales_details;
		set @end_time = GETDATE();
		PRINT 'Loading Duration: '+CAST(DATEDIFF(second,@start_time,@end_time) as NVARCHAR) + ' seconds';
		PRINT '>>----------------------------------------------------------------';

		Print '--------------------------------------------------------';
		PRINT 'Loading ERP Tables';
		Print '--------------------------------------------------------';
		--clean and load the cust_info table
		set @start_time = GETDATE();
		PRINT '>>Truncating Table : silver.erp_cust_az12';
		Truncate table silver.erp_cust_az12;
		PRINT '>>Inserting Data Into: silver.erp_cust_az12';
		INSERT INTO silver.erp_cust_az12(
			cid,
			bdate,
			gen
		)
		select 
		CASE 
			When cid LIKE 'NAS%' THEN SUBSTRING(cid , 4 , LEN(cid)) --Remove 'NAS' prefix if present
			ELSE cid
		END as cid,
		CASE 
			WHEN bdate > GETDATE() THEN NULL -- set future birthdates to null
			ELSE bdate
		END AS bdate,
		CASE 
			WHEN UPPER(TRIM(gen)) in ('F','FEMALE') THEN 'Female'
			WHEN UPPER(TRIM(gen)) in ('M','MALE') THEN 'Male'
			ELSE 'N/A'
		END AS gen --Normalize gender values and handles unknown cases
		from bronze.erp_cust_az12
		set @end_time = GETDATE();
		PRINT 'Loading Duration '+CAST(DATEDIFF(second,@start_time,@end_time) as NVARCHAR) + ' seconds';
		PRINT '>>----------------------------------------------------------------';

		--clean and load erp_loc_a101
		set @start_time = GETDATE();
		PRINT '>>Truncating Table : silver.erp_loc_a101';
		Truncate table silver.erp_loc_a101;
		PRINT '>>Inserting Data Into: silver.erp_loc_a101';
		Insert into silver.erp_loc_a101(cid,cntry)
		Select 
		Replace(cid,'-','') cid,
		CASE 
			WHEN UPPER(TRIM(cntry)) in ('DE','GERMANY')Then 'Germany'
			WHEN UPPER(TRIM(cntry)) in ('USA', 'US','UNITED STATES') THEN 'United States'
			WHEN UPPER(TRIM(cntry)) in ('AUSTRALIA') THEN 'Australia'
			WHEN UPPER(TRIM(cntry)) in ('UNITED KINGDOM') THEN 'United Kingdom'
			WHEN TRIM(cntry) = '' OR cntry is NULL THEN 'N/A'
			ELSE TRIM(cntry)
		END  as cntry
		from bronze.erp_loc_a101;
		set @end_time = GETDATE();
		PRINT 'Loading Duration '+CAST(DATEDIFF(second,@start_time,@end_time) as NVARCHAR) + ' seconds';
		PRINT '>>----------------------------------------------------------------';

		--clean and load 
		set @start_time = GETDATE();
		PRINT '>>Truncating Table : silver.erp_px_cat_g1v2';
		Truncate table silver.erp_px_cat_g1v2;
		PRINT '>>Inserting Data Into: silver.erp_px_cat_g1v2';
		Insert into silver.erp_px_cat_g1v2(
			id,
			cat,
			subcat,
			maintenance
		)
		select 
			id,
			cat,
			subcat,
			maintenance 
		from bronze.erp_px_cat_g1v2;
		set @end_time = GETDATE();
		PRINT 'Loading Duration '+CAST(DATEDIFF(second,@start_time,@end_time) as NVARCHAR) + ' seconds';
		PRINT '>>----------------------------------------------------------------';
		PRINT '===================================================================';
		PRINT 'Silver layer loading completed';
		set @batch_end_time = GETDATE();
		PRINT 'Total loading duration '+CAST(DATEDIFF(second,@batch_start_time,@batch_end_time) as NVARCHAR)+' second';

	END TRY
	BEGIN CATCH
		PRINT 'ERROR OCCURED DURING LOADING OF THE SILVER FROM BRONZE LAYER';
		PRINT 'ERROR MESSAGE' + CAST(ERROR_MESSAGE() as NVARCHAR);
		PRINT 'ERROR MESSAGE' + CAST(ERROR_NUMBER() as NVARCHAR);
		PRINT 'ERROR MESSAGE' + CAST(ERROR_STATE() as NVARCHAR);
	END CATCH
END
