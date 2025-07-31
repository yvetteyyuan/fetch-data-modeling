# Fetch Data Modeling

This repo contains scripts and queries to build data models for Fetch Rewards (a consumer shopping rewards App) and perform analytics. The project involves transforming unstructured JSON data into a structured relational data model, generating queries to answer business questions, and capturing data quality issues.

## Requirements and Deliverables

1. **Review and Transform JSON Data**
   - **Task**: Review unstructured JSON data and diagram a new structured relational data model.
   - **Deliverables**:
     - `Rewards Diagram.jpg`: ERD.
     - `fix_json_format.py`: A script to fix and format the JSON data.
     - `create_tables.py`: A script to create tables and insert data into the local PostgreSQL database.

2. **Generate Business Query**
   - **Task**: Generate a query that answers a predetermined business question.
   - **Deliverables**:
     - `queries.sql`: SQL queries to answer business questions such as identifying top brands by receipts scanned and comparing rankings between recent months.

3. **Capture Data Quality Issues**
   - **Task**: Generate a query to capture data quality issues against the new structured relational data model.
   - **Deliverables**:
     - `check_data_quality.sql`: SQL queries to check for missing values, duplicate entries, and date range issues in the `v_brands`, `v_users`, `v_receipts`, and `v_receipt_items` tables.

4. **Communicate with Stakeholders**
   - **Task**: Write a short email or Slack message to the business stakeholder.
   - **Deliverables**:
     - `slack_message.txt`: A text file containing the message to be sent to the business stakeholder.


## Usage

1. **Fix and Format JSON Data**:
   - Run the `fix_json_format.py` script to fix and format the JSON data.

2. **Create Tables and Insert Data**:
   - Run the `create_tables.py` script to create tables and insert data into the PostgreSQL database.

3. **Run Business Queries**:
   - Execute the queries in `queries.sql` to answer business questions.
   - Review the query outputs in ASCII and the concise responses in the comments below each query.

4. **Capture Data Quality Issues**:
   - Execute the queries in `check_data_quality.sql` to capture data quality issues.
   - Review the data quality overviews in the comments above each query.

5. **Communicate with Stakeholders**:
   - Review the message in `slack_message.txt` to the business stakeholder.

## Contact

For any questions or issues, please contact Yvette Yuan at [yvetteyuan.yi@gmail.com].
