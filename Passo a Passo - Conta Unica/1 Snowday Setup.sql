

USE ROLE ACCOUNTADMIN;

-- assign Query Tag to Session 
ALTER SESSION SET query_tag = '{"origin":"sf_sit-is","name":"tb_zts","version":{"major":1, "minor":1},"attributes":{"is_quickstart":1, "source":"sql", "vignette": "intro"}}';


/*Substituir
"DB_SEU_NOME" por seu nome
!!!!!!!!!!!!!!!
*/


/*
    Database objetos de desenvolvimento
*/

CREATE DATABASE IF NOT EXISTS ADMIN_DB_SEU_NOME;
CREATE SCHEMA IF NOT EXISTS ADMIN_DB_SEU_NOME.GIT;
CREATE SCHEMA IF NOT EXISTS ADMIN_DB_SEU_NOME.STREAMLIT;
CREATE SCHEMA IF NOT EXISTS ADMIN_DB_SEU_NOME.NOTEBOOK;
CREATE SCHEMA IF NOT EXISTS ADMIN_DB_SEU_NOME.DBT;

/*--
 • database, schema and warehouse creation
--*/

-- create DB_SEU_NOME database
CREATE OR REPLACE DATABASE DB_SEU_NOME;

-- create raw_pos schema
CREATE OR REPLACE SCHEMA DB_SEU_NOME.raw_pos;

-- create raw_customer schema
CREATE OR REPLACE SCHEMA DB_SEU_NOME.raw_customer;

-- create harmonized schema
CREATE OR REPLACE SCHEMA DB_SEU_NOME.harmonized;

-- create analytics schema
CREATE OR REPLACE SCHEMA DB_SEU_NOME.analytics;

-- create warehouses
CREATE OR REPLACE WAREHOUSE WH_DB_SEU_NOME
    WAREHOUSE_SIZE = 'large' -- Large for initial data load - scaled down to XSmall at end of this scripts
    WAREHOUSE_TYPE = 'standard'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
COMMENT = 'data engineering warehouse for tasty bytes';

-- create roles
USE ROLE securityadmin;

-- functional roles
CREATE ROLE IF NOT EXISTS tb_admin
    COMMENT = 'admin for tasty bytes';
    
CREATE ROLE IF NOT EXISTS tb_data_engineer
    COMMENT = 'data engineer for tasty bytes';
    
CREATE ROLE IF NOT EXISTS tb_dev
    COMMENT = 'developer for tasty bytes';
    
-- role hierarchy
GRANT ROLE tb_admin TO ROLE accountadmin;
GRANT ROLE tb_data_engineer TO ROLE tb_admin;
GRANT ROLE tb_dev TO ROLE tb_data_engineer;

-- privilege grants
USE ROLE accountadmin;

GRANT IMPORTED PRIVILEGES ON DATABASE snowflake TO ROLE tb_data_engineer;

GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE tb_admin;

USE ROLE securityadmin;

GRANT USAGE ON DATABASE DB_SEU_NOME TO ROLE tb_admin;
GRANT USAGE ON DATABASE DB_SEU_NOME TO ROLE tb_data_engineer;
GRANT USAGE ON DATABASE DB_SEU_NOME TO ROLE tb_dev;

GRANT USAGE ON ALL SCHEMAS IN DATABASE DB_SEU_NOME TO ROLE tb_admin;
GRANT USAGE ON ALL SCHEMAS IN DATABASE DB_SEU_NOME TO ROLE tb_data_engineer;
GRANT USAGE ON ALL SCHEMAS IN DATABASE DB_SEU_NOME TO ROLE tb_dev;

GRANT ALL ON SCHEMA DB_SEU_NOME.raw_pos TO ROLE tb_admin;
GRANT ALL ON SCHEMA DB_SEU_NOME.raw_pos TO ROLE tb_data_engineer;
GRANT ALL ON SCHEMA DB_SEU_NOME.raw_pos TO ROLE tb_dev;

GRANT ALL ON SCHEMA DB_SEU_NOME.harmonized TO ROLE tb_admin;
GRANT ALL ON SCHEMA DB_SEU_NOME.harmonized TO ROLE tb_data_engineer;
GRANT ALL ON SCHEMA DB_SEU_NOME.harmonized TO ROLE tb_dev;

GRANT ALL ON SCHEMA DB_SEU_NOME.analytics TO ROLE tb_admin;
GRANT ALL ON SCHEMA DB_SEU_NOME.analytics TO ROLE tb_data_engineer;
GRANT ALL ON SCHEMA DB_SEU_NOME.analytics TO ROLE tb_dev;

-- warehouse grants
GRANT OWNERSHIP ON WAREHOUSE WH_DB_SEU_NOME TO ROLE tb_admin COPY CURRENT GRANTS;
GRANT ALL ON WAREHOUSE WH_DB_SEU_NOME TO ROLE tb_admin;
GRANT ALL ON WAREHOUSE WH_DB_SEU_NOME TO ROLE tb_data_engineer;

GRANT ALL ON WAREHOUSE WH_DB_SEU_NOME TO ROLE tb_admin;
GRANT ALL ON WAREHOUSE WH_DB_SEU_NOME TO ROLE tb_data_engineer;
GRANT ALL ON WAREHOUSE WH_DB_SEU_NOME TO ROLE tb_dev;

-- future grants
GRANT ALL ON FUTURE TABLES IN SCHEMA DB_SEU_NOME.raw_pos TO ROLE tb_admin;
GRANT ALL ON FUTURE TABLES IN SCHEMA DB_SEU_NOME.raw_pos TO ROLE tb_data_engineer;
GRANT ALL ON FUTURE TABLES IN SCHEMA DB_SEU_NOME.raw_pos TO ROLE tb_dev;

GRANT ALL ON FUTURE TABLES IN SCHEMA DB_SEU_NOME.raw_customer TO ROLE tb_admin;
GRANT ALL ON FUTURE TABLES IN SCHEMA DB_SEU_NOME.raw_customer TO ROLE tb_data_engineer;
GRANT ALL ON FUTURE TABLES IN SCHEMA DB_SEU_NOME.raw_customer TO ROLE tb_dev;

GRANT ALL ON FUTURE VIEWS IN SCHEMA DB_SEU_NOME.harmonized TO ROLE tb_admin;
GRANT ALL ON FUTURE VIEWS IN SCHEMA DB_SEU_NOME.harmonized TO ROLE tb_data_engineer;
GRANT ALL ON FUTURE VIEWS IN SCHEMA DB_SEU_NOME.harmonized TO ROLE tb_dev;

GRANT ALL ON FUTURE VIEWS IN SCHEMA DB_SEU_NOME.analytics TO ROLE tb_admin;
GRANT ALL ON FUTURE VIEWS IN SCHEMA DB_SEU_NOME.analytics TO ROLE tb_data_engineer;
GRANT ALL ON FUTURE VIEWS IN SCHEMA DB_SEU_NOME.analytics TO ROLE tb_dev;

-- Apply Masking Policy Grants
USE ROLE accountadmin;
GRANT APPLY MASKING POLICY ON ACCOUNT TO ROLE tb_admin;
GRANT APPLY MASKING POLICY ON ACCOUNT TO ROLE tb_data_engineer;
  
-- raw_pos table build
USE ROLE accountadmin;
USE WAREHOUSE WH_DB_SEU_NOME;

/*--
 • file format and stage creation
--*/

CREATE OR REPLACE FILE FORMAT DB_SEU_NOME.public.csv_ff 
type = 'csv';













/*CHECKPOINT*/
/*CHECKPOINT*/
/*CHECKPOINT*/
/*CHECKPOINT*/








--Vamos trazer dados de um S3 fora do Snowflake
CREATE OR REPLACE STAGE DB_SEU_NOME.public.s3load
COMMENT = 'Quickstarts S3 Stage Connection'
url = 's3://sfquickstarts/frostbyte_tastybytes/'
file_format = DB_SEU_NOME.public.csv_ff;

/*--
 raw zone table build 
--*/

-- country table build
CREATE OR REPLACE TABLE DB_SEU_NOME.raw_pos.country
(
    country_id NUMBER(18,0),
    country VARCHAR(16777216),
    iso_currency VARCHAR(3),
    iso_country VARCHAR(2),
    city_id NUMBER(19,0),
    city VARCHAR(16777216),
    city_population VARCHAR(16777216)
);

-- franchise table build
CREATE OR REPLACE TABLE DB_SEU_NOME.raw_pos.franchise 
(
    franchise_id NUMBER(38,0),
    first_name VARCHAR(16777216),
    last_name VARCHAR(16777216),
    city VARCHAR(16777216),
    country VARCHAR(16777216),
    e_mail VARCHAR(16777216),
    phone_number VARCHAR(16777216) 
);

-- location table build
CREATE OR REPLACE TABLE DB_SEU_NOME.raw_pos.location
(
    location_id NUMBER(19,0),
    placekey VARCHAR(16777216),
    location VARCHAR(16777216),
    city VARCHAR(16777216),
    region VARCHAR(16777216),
    iso_country_code VARCHAR(16777216),
    country VARCHAR(16777216)
);

-- menu table build
CREATE OR REPLACE TABLE DB_SEU_NOME.raw_pos.menu
(
    menu_id NUMBER(19,0),
    menu_type_id NUMBER(38,0),
    menu_type VARCHAR(16777216),
    truck_brand_name VARCHAR(16777216),
    menu_item_id NUMBER(38,0),
    menu_item_name VARCHAR(16777216),
    item_category VARCHAR(16777216),
    item_subcategory VARCHAR(16777216),
    cost_of_goods_usd NUMBER(38,4),
    sale_price_usd NUMBER(38,4),
    menu_item_health_metrics_obj VARIANT
);

-- truck table build 
CREATE OR REPLACE TABLE DB_SEU_NOME.raw_pos.truck
(
    truck_id NUMBER(38,0),
    menu_type_id NUMBER(38,0),
    primary_city VARCHAR(16777216),
    region VARCHAR(16777216),
    iso_region VARCHAR(16777216),
    country VARCHAR(16777216),
    iso_country_code VARCHAR(16777216),
    franchise_flag NUMBER(38,0),
    year NUMBER(38,0),
    make VARCHAR(16777216),
    model VARCHAR(16777216),
    ev_flag NUMBER(38,0),
    franchise_id NUMBER(38,0),
    truck_opening_date DATE
);

-- order_header table build
CREATE OR REPLACE TABLE DB_SEU_NOME.raw_pos.order_header
(
    order_id NUMBER(38,0),
    truck_id NUMBER(38,0),
    location_id FLOAT,
    customer_id NUMBER(38,0),
    discount_id VARCHAR(16777216),
    shift_id NUMBER(38,0),
    shift_start_time TIME(9),
    shift_end_time TIME(9),
    order_channel VARCHAR(16777216),
    order_ts TIMESTAMP_NTZ(9),
    served_ts VARCHAR(16777216),
    order_currency VARCHAR(3),
    order_amount NUMBER(38,4),
    order_tax_amount VARCHAR(16777216),
    order_discount_amount VARCHAR(16777216),
    order_total NUMBER(38,4)
);

-- order_detail table build
CREATE OR REPLACE TABLE DB_SEU_NOME.raw_pos.order_detail 
(
    order_detail_id NUMBER(38,0),
    order_id NUMBER(38,0),
    menu_item_id NUMBER(38,0),
    discount_id VARCHAR(16777216),
    line_number NUMBER(38,0),
    quantity NUMBER(5,0),
    unit_price NUMBER(38,4),
    price NUMBER(38,4),
    order_item_discount_amount VARCHAR(16777216)
);

-- customer loyalty table build
CREATE OR REPLACE TABLE DB_SEU_NOME.raw_customer.customer_loyalty
(
    customer_id NUMBER(38,0),
    first_name VARCHAR(16777216),
    last_name VARCHAR(16777216),
    city VARCHAR(16777216),
    country VARCHAR(16777216),
    postal_code VARCHAR(16777216),
    preferred_language VARCHAR(16777216),
    gender VARCHAR(16777216),
    favourite_brand VARCHAR(16777216),
    marital_status VARCHAR(16777216),
    children_count VARCHAR(16777216),
    sign_up_date DATE,
    birthday_date DATE,
    e_mail VARCHAR(16777216),
    phone_number VARCHAR(16777216)
);

/*--
 • harmonized view creation
--*/

-- orders_v view
CREATE OR REPLACE VIEW DB_SEU_NOME.harmonized.orders_v
    AS
SELECT 
    oh.order_id,
    oh.truck_id,
    oh.order_ts,
    od.order_detail_id,
    od.line_number,
    m.truck_brand_name,
    m.menu_type,
    t.primary_city,
    t.region,
    t.country,
    t.franchise_flag,
    t.franchise_id,
    f.first_name AS franchisee_first_name,
    f.last_name AS franchisee_last_name,
    l.location_id,
    cl.customer_id,
    cl.first_name,
    cl.last_name,
    cl.e_mail,
    cl.phone_number,
    cl.children_count,
    cl.gender,
    cl.marital_status,
    od.menu_item_id,
    m.menu_item_name,
    od.quantity,
    od.unit_price,
    od.price,
    oh.order_amount,
    oh.order_tax_amount,
    oh.order_discount_amount,
    oh.order_total
FROM DB_SEU_NOME.raw_pos.order_detail od
JOIN DB_SEU_NOME.raw_pos.order_header oh
    ON od.order_id = oh.order_id
JOIN DB_SEU_NOME.raw_pos.truck t
    ON oh.truck_id = t.truck_id
JOIN DB_SEU_NOME.raw_pos.menu m
    ON od.menu_item_id = m.menu_item_id
JOIN DB_SEU_NOME.raw_pos.franchise f
    ON t.franchise_id = f.franchise_id
JOIN DB_SEU_NOME.raw_pos.location l
    ON oh.location_id = l.location_id
LEFT JOIN DB_SEU_NOME.raw_customer.customer_loyalty cl
    ON oh.customer_id = cl.customer_id;

-- loyalty_metrics_v view
CREATE OR REPLACE VIEW DB_SEU_NOME.harmonized.customer_loyalty_metrics_v
    AS
SELECT 
    cl.customer_id,
    cl.city,
    cl.country,
    cl.first_name,
    cl.last_name,
    cl.phone_number,
    cl.e_mail,
    SUM(oh.order_total) AS total_sales,
    ARRAY_AGG(DISTINCT oh.location_id) AS visited_location_ids_array
FROM DB_SEU_NOME.raw_customer.customer_loyalty cl
JOIN DB_SEU_NOME.raw_pos.order_header oh
ON cl.customer_id = oh.customer_id
GROUP BY cl.customer_id, cl.city, cl.country, cl.first_name,
cl.last_name, cl.phone_number, cl.e_mail;

/*--
 • analytics view creation
--*/

-- orders_v view
CREATE OR REPLACE VIEW DB_SEU_NOME.analytics.orders_v
COMMENT = 'Tasty Bytes Order Detail View'
    AS
SELECT DATE(o.order_ts) AS date, * FROM DB_SEU_NOME.harmonized.orders_v o;

-- customer_loyalty_metrics_v view
CREATE OR REPLACE VIEW DB_SEU_NOME.analytics.customer_loyalty_metrics_v
COMMENT = 'Tasty Bytes Customer Loyalty Member Metrics View'
    AS
SELECT * FROM DB_SEU_NOME.harmonized.customer_loyalty_metrics_v;

/*--
 raw zone table load 
--*/

-- country table load
COPY INTO DB_SEU_NOME.raw_pos.country
FROM @DB_SEU_NOME.public.s3load/raw_pos/country/;

-- franchise table load
COPY INTO DB_SEU_NOME.raw_pos.franchise
FROM @DB_SEU_NOME.public.s3load/raw_pos/franchise/;

-- location table load
COPY INTO DB_SEU_NOME.raw_pos.location
FROM @DB_SEU_NOME.public.s3load/raw_pos/location/;

-- menu table load
COPY INTO DB_SEU_NOME.raw_pos.menu
FROM @DB_SEU_NOME.public.s3load/raw_pos/menu/;

-- truck table load
COPY INTO DB_SEU_NOME.raw_pos.truck
FROM @DB_SEU_NOME.public.s3load/raw_pos/truck/;

-- customer_loyalty table load
COPY INTO DB_SEU_NOME.raw_customer.customer_loyalty
FROM @DB_SEU_NOME.public.s3load/raw_customer/customer_loyalty/;

-- order_header table load
COPY INTO DB_SEU_NOME.raw_pos.order_header
FROM @DB_SEU_NOME.public.s3load/raw_pos/order_header/;

ALTER WAREHOUSE WH_DB_SEU_NOME SET WAREHOUSE_SIZE = 'XSMALL';

-- order_detail table load





/* Vamos trabalhar com escalabilidade na prática 


--Quanto tempo demora para importar os dados com um cluster XS?
COPY INTO DB_SEU_NOME.raw_pos.order_detail
FROM @DB_SEU_NOME.public.s3load/raw_pos/order_detail/;


--Vamos aumentar o poder de processamento
ALTER WAREHOUSE WH_DB_SEU_NOME SET WAREHOUSE_SIZE = 'XLARGE';


COPY INTO DB_SEU_NOME.raw_pos.order_detail
FROM @DB_SEU_NOME.public.s3load/raw_pos/order_detail/;


ALTER WAREHOUSE WH_DB_SEU_NOME SET WAREHOUSE_SIZE = 'XSMALL';

SELECT COUNT(*) FROM DB_SEU_NOME.raw_pos.order_detail;