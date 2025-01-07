there are duplicate user_id values in your JSON data, which violates the primary key constraint on the v_users table.
--The script now uses a set to track unique user_id values and remove duplicates before inserting them into the table.

same issue as above with brands

brands: barcode not always matching with receipt items barcode. brand barcodes all start with 51111 but receipt items barcodes have other formats. i.e. no 2021-02 barcodes in receipt items are found in brands barcodes;
 Given the discrepancy in barcode formats, partial matching or data enrichment might be necessary to improve the join results. If partial matching is not reliable, consider enriching the data or accepting that some records will be dropped.  If possible, enrich the data to ensure that the barcodes in the receipt items can be matched with the barcodes in the formatted brands.

the file is not formatted as a single valid JSON document. Enclose all JSON objects in an array.Ensure that each JSON object is separated by a comma.
--write a python script to properly format the raw data

JSON file contains improperly formatted JSON objects or if there are empty lines or other non-JSON content in the file.
--add more robust error handling to skip lines that cannot be parsed as JSON.

some user records in your JSON data do not have the lastLogin/state/signupsource field. 
--The script now provides a default value (None) if the lastLogin field is missing.

-------------------------- Data quality check - v_users --------------------------------
-- No missing values except for last_login(172/212), sign_up_source(207/212), state(206/212)
select
  count(*) as total_records
  ,count(user_id) as user_id_count
  ,count(active) as active_count
  ,count(created_date) as created_date_count
  ,count(last_login) as last_login_count
  ,count("role") as role_count
  ,count(sign_up_source) as sign_up_source_count
  ,count("state") as state_count
from v_users;

-- No duplicate v_users user_id because of the de-duplication in create_tables.py
select
  user_id
  ,count(*) as count
from v_users
group by 1
having count(*) > 1;

-- Date range for account creation: 2014-12-19 to 2021-02-12
-- Date range for last login: 2018-05-08 to 2021-03-06
select
  min(created_date) as min_created_date
  ,max(created_date) as max_created_date
  ,min(last_login) as min_last_login
  ,max(last_login) as max_last_login
from v_users;

-------------------------- Data quality check - v_brands --------------------------------
-- No missing or null v_brands barcodes (1160/1160), name (1160/1160), brand_id (1160/1160)
select
  count(*) as total_records
  ,count(brand_id) as brand_id_count
  ,count(barcode) as barcode_count
  ,count("name") as name_count
from v_brands;

-- No duplicate v_brands barcodes because of the de-duplication in create_tables.py
select
  barcode
  ,count(*) as count
from v_brands
group by 1
having count(*) > 1;

-------------------------- Data quality check - v_receipts and v_receipt_items --------------------------------
-- No missing receipt_id, user_id, create_date, scanned_date, total_spent, rewards_receipt_status
-- Missing purchase_date (671/1119), finished_date (568/1119), points_awarded_date (537/1119)
-- purchased_item_total is 9371
-- bonus_points_earned_total is 129,958, less than points_earned_total 356,851
select
  count(*) as total_records
  ,count(receipt_id) as receipt_id_count
  ,count(user_id) as user_id_count
  ,count(create_date) as create_date_count
  ,count(scanned_date) as scanned_date_count
  ,count(purchase_date) as purchase_date_count
  ,count(finished_date) as finished_date_count
  ,count(points_awarded_date) as points_awarded_date_count
  ,count(total_spent) as total_spent_count
  ,count(rewards_receipt_status) as rewards_receipt_status_count
  ,sum(purchased_item_count) as purchased_item_count_total
  ,sum(bonus_points_earned) as bonus_points_earned_total
  ,sum(points_earned) as points_earned_total  
from v_receipts;

-- No missing receipt_item_id
-- Some receipts are missing the item array : 679 unique receipt_ids in v_receipt_items vs 1119 in v_receipts
-- Missing barcode (3090/6941), final_price (6767/6941), item_price (6767/6941), quantity_purchased (6767/6941)
-- Missing distinct barcodes: 568 in v_receipt_items, less than the 1160 barcodes in v_brands
-- quantity_purchased_total slightly mismatched: 9380 in v_receipt_items vs purchased_item_total 9371 in v_receipts
select
  count(*) as total_records
  ,count(receipt_item_id) as receipt_item_id_count
  ,count(distinct receipt_id) as receipt_id_count -- 679 unique receipt_ids
  ,count(receipt_id) as receipt_id_count
  ,count(barcode) as barcode_count
  ,count(distinct barcode) as barcode_count
  ,count(description) as description_count
  ,count(final_price) as final_price_count
  ,count(item_price) as item_price_count
  ,count(quantity_purchased) as quantity_purchased_count
  ,sum(quantity_purchased) as quantity_purchased_total
from v_receipt_items;

-- No duplicate receipt entries
select
  receipt_id
  ,count(*) as count
from v_receipts
group by 1
having count(*) > 1;

-- No duplicate receipt item entries
select
  receipt_item_id
  ,count(*) as count
from v_receipt_items
group by 1
having count(*) > 1;

-- Date range for purchases: 2017-10-30 to 2021-03-09, widest date range possibly includes historical transactions?
-- Date range for scans/receipt creations: 2020-10-31 to 2021-03-02
-- Date range for finished_date: 2021-01-04 to 2021-02-27 narrowest date range
-- Date range for points awarded: 2020-10-31 to 2021-02-27
select
  min(purchase_date) as purchase_date_min
  ,max(purchase_date) as purchase_date_max
  ,min(scanned_date) as scanned_date_min
  ,max(scanned_date) as scanned_date_max
  ,min(finished_date) as finished_date_min
  ,max(finished_date) as finished_date_max
  ,min(points_awarded_date) as points_awarded_date_min
  ,max(points_awarded_date) as points_awarded_date_max
from v_receipts;

-- Inconsistent price data (1143/6941): final_price not matching item_price * quantity_purchased
select
  receipt_item_id
  ,final_price
  ,item_price
  ,quantity_purchased
from v_receipt_items
where final_price::float != item_price::float * quantity_purchased::float;