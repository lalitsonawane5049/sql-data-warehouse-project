


-- first row is header so consider second row as first
--each field is separated by comma
--TABLOCK is used to specify that during inserting no could access the table.
--Quality check : check that the data has not shifted and is in the correct columns. 
--Create stored procedure 
--Use try catch block
--Calculate the duration for loading tables
--Calculate whole batch duration
Create or Alter Procedure bronze.load_bronze as
BEGIN
	BEGIN TRY 
		DECLARE @start_time DATETIME , @end_time DATETIME , @batch_start_time DATETIME , @batch_end_time DATETIME;
		SET @batch_start_time = GETDATE();
		PRINT '========================================================';
		PRINT 'Loading Bronze Layer';
		PRINT '========================================================';
	
		Print '--------------------------------------------------------';
		PRINT 'Loading CRM Tables';
		Print '--------------------------------------------------------';
		SET @start_time = GETDATE();
		PRINT'>> Truncating Table: bronze.crm_cust_info';
		Truncate Table bronze.crm_cust_info;

		Print'>> Inserting Data Into: bronze.crm_cust_info';
		--empty table first then insert data
		BULK INSERT bronze.crm_cust_info
		from 'D:\SQL Project\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		with(
			Firstrow = 2,
			Fieldterminator = ',',
			TABLOCK
		);
		set @end_time = GETDATE();
		PRINT 'Loading Duration: ' + CAST(DATEDIFF(SECOND,@start_time ,@end_time) AS NVARCHAR) + 'seconds';
		PRINT '>>-------------------';

		SET @start_time = GETDATE();
		PRINT'>> Truncating Table: bronze.crm_prd_info';
		Truncate Table bronze.crm_prd_info;

		Print'>> Inserting Data Into: bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		from 'D:\SQL Project\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		with(
			Firstrow = 2,
			Fieldterminator = ',',
			TABLOCK
		);
		set @end_time = GETDATE();
		PRINT 'Loading Duration: ' + CAST(DATEDIFF(SECOND,@start_time ,@end_time) AS NVARCHAR) + 'seconds';
		PRINT '>>-------------------';
		
		SET @start_time = GETDATE();
		PRINT'>> Truncating Table: crm_sales_details';
		Truncate Table bronze.crm_sales_details;

		Print'>> Inserting Data Into: crm_sales_details';
		BULK Insert bronze.crm_sales_details
		from 'D:\SQL Project\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		with(
			Firstrow = 2,
			Fieldterminator = ',',
			TABLOCK
		);
		set @end_time = GETDATE();
		PRINT 'Loading Duration: ' + CAST(DATEDIFF(SECOND,@start_time ,@end_time) AS NVARCHAR) + 'seconds';
		PRINT '>>-------------------';


		Print '--------------------------------------------------------';
		PRINT 'Loading ERP Tables';
		Print '--------------------------------------------------------';
		
		SET @start_time = GETDATE();
		PRINT'>> Truncating Table: bronze.erp_cust_az12';
		Truncate Table bronze.erp_cust_az12;

		Print'>> Inserting Data Into: bronze.erp_cust_az12';
		Bulk insert bronze.erp_cust_az12
		from 'D:\SQL Project\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		with(
			firstrow = 2,
			fieldterminator = ',',
			TABLOCK
		);
		set @end_time = GETDATE();
		PRINT 'Loading Duration: ' + CAST(DATEDIFF(SECOND,@start_time ,@end_time) AS NVARCHAR) + 'seconds';
		PRINT '>>-------------------';

		SET @start_time = GETDATE();
		PRINT'>> Truncating Table: bronze.erp_loc_a101';
		Truncate Table bronze.erp_loc_a101;

		Print'>> Inserting Data Into: bronze.erp_loc_a101';
		Bulk insert bronze.erp_loc_a101
		from 'D:\SQL Project\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		with(
			Firstrow = 2,
			fieldterminator = ',',
			TABLOCK
		);
		set @end_time = GETDATE();
		PRINT 'Loading Duration: ' + CAST(DATEDIFF(SECOND,@start_time ,@end_time) AS NVARCHAR) + 'seconds';
		PRINT '>>-------------------';

		SET @start_time = GETDATE();
		PRINT'>> Truncating Table: bronze.erp_px_cat_g1v2';
		Truncate Table bronze.erp_px_cat_g1v2;

		Print'>> Inserting Data Into: bronze.erp_px_cat_g1v2';
		Bulk Insert bronze.erp_px_cat_g1v2
		from 'D:\SQL Project\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		with(
			Firstrow = 2,
			fieldterminator = ',',
			Tablock
		);
		set @end_time = GETDATE();
		PRINT 'Loading Duration: ' + CAST(DATEDIFF(SECOND,@start_time ,@end_time) AS NVARCHAR) + 'seconds';
		PRINT '>>-------------------';

		set @batch_end_time = GETDATE();
		PRINT '>>---------------------';
		Print 'Loading Bronze Layer is Completed ';
		PRINT 'Loading Duration of whole batch: '+CAST(DATEDIFF(SECOND,@batch_start_time,@batch_end_time) AS NVARCHAR) + 'seconds';
		PRINT '>>-------------------';
	END TRY
	BEGIN CATCH
		PRINT '=======================================================================';
		PRINT 'ERROR OCCURED During Loading Bronze Layer ' ;
		PRINT 'ERROR MESSAGE '+ CAST(ERROR_MESSAGE() AS NVARCHAR);
		PRINT 'ERROR MESSAGE '+ CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR MESSAGE '+ CAST(ERROR_NUMBER() AS NVARCHAR);
	END CATCH;
END;
