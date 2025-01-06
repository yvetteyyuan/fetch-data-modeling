import psycopg2
import json
import os

# Define the paths to the JSON files
users_file_path = 'C:/Users/Yvette.Yuan/Downloads/fetch2024/formatted_users.json'
receipts_file_path = 'C:/Users/Yvette.Yuan/Downloads/fetch2024/formatted_receipts.json'
brands_file_path = 'C:/Users/Yvette.Yuan/Downloads/fetch2024/formatted_brands.json'

# Check if files exist
if not os.path.exists(users_file_path):
	raise FileNotFoundError(f"No such file or directory: '{users_file_path}'")
if not os.path.exists(receipts_file_path):
	raise FileNotFoundError(f"No such file or directory: '{receipts_file_path}'")
if not os.path.exists(brands_file_path):
	raise FileNotFoundError(f"No such file or directory: '{brands_file_path}'")

# Connect to PostgreSQL
conn = psycopg2.connect(
    dbname="fetch_db",
    user="postgres",
    password="Sanfran12#",
    host="localhost",
    port="5434"
)
cur = conn.cursor()

# Drop tables if they already exist
cur.execute('DROP TABLE IF EXISTS v_users')
cur.execute('DROP TABLE IF EXISTS v_receipts')
cur.execute('DROP TABLE IF EXISTS v_receipt_items')
cur.execute('DROP TABLE IF EXISTS v_brands')

# Create tables
cur.execute('''
CREATE TABLE v_users (
	user_id TEXT PRIMARY KEY,
	active BOOLEAN,
	created_date TIMESTAMP,
	last_login TIMESTAMP,
	role TEXT,
	sign_up_source TEXT,
	state TEXT
)
''')

cur.execute('''
CREATE TABLE v_receipts (
	receipt_id TEXT PRIMARY KEY,
	user_id TEXT,
	bonus_points_earned INTEGER,
	bonus_points_earned_reason TEXT,
	create_date TIMESTAMP,
	scanned_date TIMESTAMP,
	finished_date TIMESTAMP,
	modify_date TIMESTAMP,
	points_awarded_date TIMESTAMP,
	points_earned FLOAT,
	purchase_date TIMESTAMP,
	purchased_item_count INTEGER,
	rewards_receipt_status TEXT,
	total_spent FLOAT
)
''')

cur.execute('''
CREATE TABLE v_receipt_items (
    receipt_item_id SERIAL PRIMARY KEY,
    receipt_id TEXT,
    barcode TEXT,
    description TEXT,
    final_price FLOAT,
    discontinued_item_price FLOAT,
    item_price FLOAT,
    needs_fetch_review BOOLEAN,
    partner_item_id TEXT,
    prevent_target_gap_points BOOLEAN,
    quantity_purchased INTEGER,
    user_flagged_barcode TEXT,
    user_flagged_new_item BOOLEAN,
    user_flagged_price FLOAT,
    user_flagged_quantity INTEGER,
    rewards_group TEXT,
    rewards_product_partner_id TEXT,
    points_not_awarded_reason TEXT,
    points_payer_id TEXT,
    needs_fetch_review_reason TEXT
)
''')

cur.execute('''
CREATE TABLE v_brands (
	barcode TEXT PRIMARY KEY,
    brand_id TEXT,
	category TEXT,
	category_code TEXT,
	cpg_id TEXT,
	name TEXT,
	top_brand BOOLEAN,
	brand_code TEXT
)
''')

# Load and insert users data
with open(users_file_path, 'r') as f:
    users_data = json.load(f)
    unique_users = set()
    for user in users_data:
        user_id = user['_id']['$oid']
        if user_id not in unique_users:
            unique_users.add(user_id)
            created_date = user['createdDate']['$date']
            last_login = user.get('lastLogin', {}).get('$date', None)
            state = user.get('state', None)
            sign_up_source = user.get('signUpSource', None)
            cur.execute('''
            INSERT INTO v_users (user_id, active, created_date, last_login, role, sign_up_source, state)
            VALUES (%s, %s, to_timestamp(%s / 1000), to_timestamp(%s / 1000), %s, %s, %s)
            ''', (
                user_id,
                user['active'],
                created_date,
                last_login,
                user['role'],
                sign_up_source,
                state
            ))

# Load and insert receipts data
with open(receipts_file_path, 'r') as f:
    receipts_data = json.load(f)
    for receipt in receipts_data:
        bonus_points_earned = receipt.get('bonusPointsEarned', 0)
        bonus_points_earned_reason = receipt.get('bonusPointsEarnedReason', None)
        points_earned = receipt.get('pointsEarned', 0)
        finished_date = receipt.get('finishedDate', {}).get('$date', None)
        modify_date = receipt.get('modifyDate', {}).get('$date', None)
        points_awarded_date = receipt.get('pointsAwardedDate', {}).get('$date', None)
        purchase_date = receipt.get('purchaseDate', {}).get('$date', None)
        purchased_item_count = receipt.get('purchasedItemCount', 0)
        total_spent = receipt.get('totalSpent', 0.0)        
        cur.execute('''
        INSERT INTO v_receipts (receipt_id, user_id, bonus_points_earned, bonus_points_earned_reason, create_date, scanned_date, finished_date, modify_date, points_awarded_date, points_earned, purchase_date, purchased_item_count, rewards_receipt_status, total_spent)
        VALUES (%s, %s, %s, %s, to_timestamp(%s / 1000), to_timestamp(%s / 1000), to_timestamp(%s / 1000), to_timestamp(%s / 1000), to_timestamp(%s / 1000), %s, to_timestamp(%s / 1000), %s, %s, %s)
        ''', (
            receipt['_id']['$oid'],
            receipt['userId'],
            bonus_points_earned,
            bonus_points_earned_reason,
            receipt['createDate']['$date'],
            receipt['dateScanned']['$date'],
            finished_date,
            modify_date,
            points_awarded_date,
            points_earned,
            purchase_date,
            purchased_item_count,
            receipt['rewardsReceiptStatus'],
            total_spent
        ))

        rewards_receipt_item_list = receipt.get('rewardsReceiptItemList', [])
        for item in rewards_receipt_item_list:
            cur.execute('''
            INSERT INTO v_receipt_items (receipt_id, barcode, description, final_price, discontinued_item_price, item_price, needs_fetch_review, partner_item_id, prevent_target_gap_points, quantity_purchased, user_flagged_barcode, user_flagged_new_item, user_flagged_price, user_flagged_quantity, rewards_group, rewards_product_partner_id, points_not_awarded_reason, points_payer_id, needs_fetch_review_reason)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            ''', (
                receipt['_id']['$oid'],
                item.get('barcode'),
                item.get('description'),
                item.get('finalPrice'),
                item.get('discountedItemPrice'),
                item.get('itemPrice'),
                item.get('needsFetchReview'),
                item.get('partnerItemId'),
                item.get('preventTargetGapPoints'),
                item.get('quantityPurchased'),
                item.get('userFlaggedBarcode'),
                item.get('userFlaggedNewItem'),
                item.get('userFlaggedPrice'),
                item.get('userFlaggedQuantity'),
                item.get('rewardsGroup'),
                item.get('rewardsProductPartnerId'),
                item.get('pointsNotAwardedReason'),
                item.get('pointsPayerId'),
                item.get('needsFetchReviewReason')
            ))

# Load and insert brands data
with open(brands_file_path, 'r') as f:
    brands_data = json.load(f)
    unique_barcodes = set()
    for brand in brands_data:
        barcode = brand.get('barcode', None)
        if barcode not in unique_barcodes:
            unique_barcodes.add(barcode)
            brand_id = brand['_id']['$oid']
            category = brand.get('category', None)
            category_code = brand.get('categoryCode', None)
            cpg_id = brand['cpg']['$id']['$oid']
            name = brand.get('name', None)
            top_brand = brand.get('topBrand', False)
            brand_code = brand.get('brandCode', None)
            cur.execute('''
            INSERT INTO v_brands (barcode, brand_id, category, category_code, cpg_id, name, top_brand, brand_code)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            ''', (
                barcode,
                brand_id,
                category,
                category_code,
                cpg_id,
                name,
                top_brand,
                brand_code
            ))

# Commit and close the connection
conn.commit()
cur.close()
conn.close()