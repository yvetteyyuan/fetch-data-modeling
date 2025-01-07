-- Written in PostgreSQL 12
--------------------------------------------------------------------------------------------------------------------------------------
/* What are the top 5 brands by receipts scanned for most recent month?
   How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the previous month?
*/
with 
  max_date as (
    select max(scanned_date) as max_scanned_date
    from v_receipts
  )
  ,recent_receipts as (
    -- Filter for the two most recently *completed* month
    select
      scanned_date
      ,r.receipt_id
      ,ri.barcode
	  ,nullif(ri.description,'ITEM NOT FOUND') as item_description
    from v_receipts r
    join max_date md
      on r.scanned_date >= date_trunc('month', md.max_scanned_date) - interval '2 month'
        and r.scanned_date < date_trunc('month', md.max_scanned_date)
    left join v_receipt_items ri
      on r.receipt_id = ri.receipt_id order by 3
  )
  ,brand_receipts as (
    -- 2021-02 transactions have no matching barcode between v_brands and v_receipt_items
    -- Due to the discrepancy in barcode formats between v_brands and v_receipt_items, we enrich brand name with receipt item descriptions
    select
      date_trunc('month', rr.scanned_date) as scanned_month
      ,lower(coalesce(b.name,split_part(item_description,' ',1))) as brand_name
      ,count(rr.receipt_id) as receipt_count
    from recent_receipts rr
    left join v_brands b 
      on rr.barcode = b.barcode
    group by 1,2
  )
  ,ranked_brands as (
    -- Use rank() to return a more concise list of top brands, leaving gaps in the ranking values when there are ties
    select
      scanned_month
      ,case
        when brand_name = 'ben' then 'ben & jerrys'
        when brand_name = 'capri' then 'capri sun'
        else brand_name
	    end::varchar as brand_name
      ,receipt_count
      ,rank() over (partition by scanned_month order by receipt_count desc) as rk
    from brand_receipts
	  where brand_name is not null and brand_name != 'deleted'  -- Only return informative brand names
  )
select
  -- Find the top 5 brands by receipts scanned in the most recent month
  -- Compare the ranking of those 5 brands between the most recent month and the prior month
  recent.brand_name
  ,recent.rk as recent_month_rank
  ,recent.receipt_count as recent_month_receipt_count
  ,previous.rk as previous_month_rank
  ,previous.receipt_count as previous_month_receipt_count
from ranked_brands previous
left join ranked_brands recent
  on recent.brand_name = previous.brand_name 
    and previous.scanned_month = recent.scanned_month - interval '1 month'
where recent.rk <= 5 
order by 2, 4;

/* Output from query above. 
   The brand names are enriched with receipt item descriptions, but the data quality is not great - there are no matching barcodes between v_brands and v_receipt_items for the most recent completed month. 
   This results in receipts not properly associated with brands. 
+---+----------+--------------------+-------------------------+---------------------+---------------------------+
| # | Brand    | Recent Month Rank  | Recent Month Receipt Ct | Previous Month Rank | Previous Month Receipt Ct |
+---+----------+--------------------+-------------------------+---------------------+---------------------------+
| 1 | flipbelt | 1                  | 28                      | 42                  | 22                        |
| 2 | mueller  | 2                  | 22                      | 274                 | 4                         |
| 3 | thindust | 2                  | 22                      | 274                 | 4                         |
| 4 | heinz    | 4                  | 10                      | 42                  | 22                        |
| 5 | doritos  | 5                  | 3                       | 11                  | 92                        |
+---+----------+--------------------+-------------------------+---------------------+---------------------------+
*/

--------------------------------------------------------------------------------------------------------------------------------------
/* When considering average spend from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
*/
select
  -- FINISHED/REJECTED are the reward statuses that correspond to Accepted/Rejected
  case 
  	when rewards_receipt_status = 'FINISHED' then 'ACCEPTED'
	  else rewards_receipt_status
  end::varchar as rewards_receipt_status
  ,avg(total_spent) as average_spend
from v_receipts
where rewards_receipt_status in ('FINISHED', 'REJECTED')
group by 1;

/* Output from query above. 
   The average spend for receipts with 'rewardsReceiptStatus’ of ‘Accepted’ is greater than ‘Rejected’. 
+---+------------+----------------------+
| # | Status     | Average Spend       |
+---+------------+----------------------+
| 1 | REJECTED   | 23.33               |
| 2 | ACCEPTED   | 80.85               |
+---+------------+----------------------+
*/

--------------------------------------------------------------------------------------------------------------------------------------
/* When considering total number of items purchased from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
*/
select
  case 
  	when r.rewards_receipt_status = 'FINISHED' then 'ACCEPTED'
	  else r.rewards_receipt_status
  end::varchar as rewards_receipt_status
  ,sum(ri.quantity_purchased) as total_items_purchased
from v_receipts r
join v_receipt_items ri 
  on r.receipt_id = ri.receipt_id
where r.rewards_receipt_status in ('FINISHED', 'REJECTED')
group by 1;

/* Output from query above. 
   The total number of items purchased for receipts with 'rewardsReceiptStatus’ of ‘Accepted’ is greater than ‘Rejected’.
+---+------------+----------------------+
| # | Status     | Total Items         |
+---+------------+----------------------+
| 1 | REJECTED   | 141                 |
| 2 | ACCEPTED   | 8176                |
+---+------------+----------------------+
*/

--------------------------------------------------------------------------------------------------------------------------------------
/* Which brand has the most spend among users who were created within the past 6 months?
*/
with 
  max_date as (
    -- Take the most recent scan date 2021-03 as the most recent date, because no users were created beyond 2021-02 
    select max(scanned_date) as max_scanned_date
    from v_receipts
  )
  ,recent_users as (
    select user_id
    from v_users,max_date
    where created_date >= max_scanned_date - interval '6 months'
  )
  ,recent_user_receipts as (
    select 
      r.receipt_id
      ,r.user_id
      ,r.total_spent
    from v_receipts r
    join recent_users u
      on r.user_id = u.user_id
  )
  ,recent_barcode_spend as (
    -- Due to the discrepancy in barcode formats between v_brands and v_receipt_items, we enrich brand name with receipt item descriptions
    select
      ri.barcode
	    ,split_part(ri.description,' ', 1) as enriched_brand
      ,sum(r.total_spent) as total_spend
    from recent_user_receipts r
    join v_receipt_items ri
      on r.receipt_id = ri.receipt_id
    group by 1,2
  )
select 
  lower(coalesce(b.name,enriched_brand)) as brand_name
  ,bs.total_spend
from recent_barcode_spend bs
left join v_brands b
  on bs.barcode = b.barcode
order by 2 desc
limit 1;

/* Output from query above. 
   Enriching brand names with item descriptions, PC has the highest spend at $364425.01 among users who were created the past 6 mo.
   Without enriching brand names with item descriptions, Tostitos has the highest spend at $15799 among users who were created the past 6 mo 
   This is far from accurate because lots of brand names are missing due to the barcode format inconsistency. 
+---+------------+--------------------+
| # | Brand Name | Total Spend        |
+---+------------+--------------------+
| 1 | pc         | 364425.01         |
+---+------------+--------------------+
*/
--------------------------------------------------------------------------------------------------------------------------------------
/* Which brand has the most transactions among users who were created within the past 6 months?
*/
with 
  max_date as (
    -- Reuse most the code above
    select max(scanned_date) as max_scanned_date
    from v_receipts
  )
  ,recent_users as (
    select user_id
    from v_users,max_date
    where created_date >= max_scanned_date - interval '6 months'
  )
  ,recent_user_receipts as (
    select 
      r.receipt_id
      ,r.user_id
      ,r.total_spent
    from v_receipts r
    join recent_users u
      on r.user_id = u.user_id
  )
  ,recent_barcode_trans as (
    select
      ri.barcode
      ,split_part(ri.description,' ', 1) as enriched_brand
      ,count(r.receipt_id) as transaction_count
    from recent_user_receipts r
    join v_receipt_items ri
      on r.receipt_id = ri.receipt_id
    group by 1,2
  )
select 
  lower(coalesce(b.name,enriched_brand)) as brand_name
  ,bt.transaction_count
from recent_barcode_trans bt
left join v_brands b
  on bt.barcode = b.barcode
order by 2 desc
limit 1;

/* Output from query above. 
   Enriching brand names with item descriptions, Hyv has the most transactions (237) among users who were created the past 6 mo.
   Without enriching brand names with item descriptions, Tostitos has the most transactions (23) among users who were created the past 6 mo 
   This is far from accurate because lots of brand names are missing due to the barcode format inconsistency. 
+---+------------+-------------------+
| # | Brand Name | Transaction Count |
+---+------------+-------------------+
| 1 | hyv        | 237              |
+---+------------+-------------------+
*/