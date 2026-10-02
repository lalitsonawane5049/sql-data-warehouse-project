--Quality check for customers
Select cst_id, count(*) From(
	Select 
		ci.[cst_id],
		ci.[cst_key],
		ci.[cst_firstname],
		ci.[cst_lastname],
		ci.[cst_marital_status],
		ci.[cst_gndr],
		ci.[cst_create_date],
		ca.bdate,
		ca.gen,
		la.cntry
	From silver.crm_cust_info as ci
	LEFT JOIN silver.erp_cust_az12 ca
	on ci.cst_key = ca.cid
	LEFT JOIN silver.erp_loc_a101 la
	on ci.cst_key = la.cid) t
group by cst_id having count(*) > 1;

-- There are two columns for gender check the reliability.
select distinct
	ci.cst_gndr,
	ca.gen,
	CASE 
		WHEN ci.cst_gndr  != 'N/A' THEN ci.cst_gndr -- CRM is the Master for gender INFO
		ELSE COALESCE(ca.gen,'N/A')
	END as new_gen
from silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key =  la.cid

--Quality Check of gold.dim_customers
SElect distinct gender from gold.dim_customers;

--Quality check for  producer
--Quality check
select prd_key, count(*) from(
select 
	pn.[prd_id],
	pn.[cat_id],
	pn.[prd_key],
	pn.[prd_nm],
	pn.[prd_cost],
	pn.[prd_line],
	pn.[prd_start_dt],
	pn.[prd_end_dt],
	pc.cat,
	pc.subcat,
	pc.maintenance
from silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
On pn.cat_id = pc.id
Where prd_end_dt is NULL) t -- Filter out all historical data
group by  prd_key having prd_key > 1

--Quality check for sales
--quality check and fact check
select * from gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key where c.customer_key is NULL;

select * from gold.fact_sales f
LEFT JOIN gold.dim_products c
ON c.product_key = f.product_key where c.product_key is NULL;
