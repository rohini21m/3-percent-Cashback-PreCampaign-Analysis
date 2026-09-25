KPI_1 : baseline_per_category Logic : 
SELECT 
    merchant_code, 
    merchant_code_description,
    p.product_name,
    SUM(trnx_amt) AS total_yearly_spend_per_category,   
    CONCAT('$', ROUND(SUM(trnx_amt) / 1000000.0, 1), 'M') AS yearly_category_spend_in_millions,
    
    -- 1. Fixed: Forcing a decimal division (.0) so decimals don't get truncated
    ROUND(SUM(trnx_amt) / 12.0, 2) AS avg_monthly_spend_per_category,
    
    -- 2. Fixed: Total Yearly Spend divided by Unique Customers (Formatted nicely)
    ROUND(SUM(trnx_amt) / COUNT(DISTINCT account_id), 2) AS avg_yearly_spend_per_customer_per_category,
    
    -- 3. Added: If you DID want monthly spend per customer, do the math all at once
    ROUND((SUM(trnx_amt) / 12.0) / COUNT(DISTINCT account_id), 2) AS avg_monthly_spend_per_customer_per_category

FROM RFM_ANALYSIS.fact_transactions f 
INNER JOIN RFM_ANALYSIS.dim_products p 
    ON f.product_code = p.product_code  
WHERE trnx_date >= '2025-01-01' 
  AND trnx_date <= '2025-12-31'
  AND f.product_code='101'
  AND f.merchant_code IN ('9135', '9144', '9147', '9149') 
GROUP BY merchant_code, merchant_code_description, product_name

--------------------------------------------
KPI2 : Transaction_Volume logic :
---transaction_volume : catgeory_trnx_count in 2025
select p.product_name,Concat('Q',to_char(trnx_date,'Q')) as Quarters,
count(trnx_id)filter(where f.merchant_code_description LIKE '%Groceries%') as total_captured_grocery_trnxs,
count(trnx_id)filter(where f.merchant_code_description LIKE '%Streaming%') as total_captured_streaming_trnxs,
count(trnx_id)filter(where f.merchant_code_description LIKE '%Restaurant%') as total_captured_Restaurant_trnxs
from RFM_ANALYSIS.fact_transactions f 
inner join RFM_ANALYSIS.dim_products p 
on f.product_code=p.product_code 
where f.trnx_date>='01-01-2025' 
and f.trnx_date<='12-31-2025'
and f.product_code in ('101','102') 
and f.merchant_code in ('9135', '9144', '9147', '9149') 
group by p.product_name ,to_char(trnx_date,'Q') 

-----------------------------------
KPI3 : Portfolio Customer Segment Distribution (Q1 Window)
-- we need to check spending all 3 categories beyond 1500 
with all_combined_category_spend_cte as (
select p.product_name as CreditCard_Name,
account_id,
sum(trnx_amt) as total_Q1_card_purchases 
from RFM_ANALYSIS.fact_transactions f 
inner join RFM_ANALYSIS.dim_products p 
on p.product_code=f.product_code
WHERE trnx_date >= '2025-01-01' AND trnx_date <= '2025-03-31' 
AND p.product_code='101'
AND merchant_code IN ('9135', '9144', '9147', '9149') 
GROUP by product_name,account_id
), combined_spending_segmentation as(
select account_id, 
total_Q1_card_purchases,
CreditCard_Name,
case when total_Q1_card_purchases>1500 then 'High_Spending_Accounts' 
when  total_Q1_card_purchases>750 AND total_Q1_card_purchases <=1500 then 'Medium_Spending_Accounts'
else 'Low_Spending_Accounts'  
end as categories_combined_spending_groups
from all_combined_category_spend_cte
) 
select CreditCard_Name,categories_combined_spending_groups,
sum(total_Q1_card_purchases) as cummulative_Q1_Spend_by_all_accts,
count(distinct account_id) as Total_Accounts,
round(sum(total_Q1_card_purchases)/count(distinct account_id),2) as avg_spend_per_account_in_Q1
from combined_spending_segmentation
group by categories_combined_spending_groups,CreditCard_Name




