/*atualizar atualizar atualizar*/
/*atualizar atualizar atualizar*/
DB_SEU_NOME para DB_SEU_NOME;
/*atualizar atualizar atualizar*/
/*atualizar atualizar atualizar*/

USE WAREHOUSE WH_DB_SEU_NOME;
USE ROLE ACCOUNTADMIN;

SHOW ROLES;

    
SELECT
    "name",
    "comment"
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "name" IN ('ORGADMIN','ACCOUNTADMIN','SYSADMIN','USERADMIN','SECURITYADMIN','PUBLIC');
    

--Criar uma nova Role    
USE ROLE useradmin;
--Criação de novo perfil de usuário e suas permissões
CREATE OR REPLACE ROLE ANALISTA_JR_DB_SEU_NOME;



begin

    GRANT ALL ON WAREHOUSE WH_DB_SEU_NOME TO ROLE ANALISTA_JR_DB_SEU_NOME
    GRANT USAGE ON DATABASE DB_SEU_NOME TO ROLE ANALISTA_JR_DB_SEU_NOME
    GRANT USAGE ON ALL SCHEMAS IN DATABASE DB_SEU_NOME TO ROLE ANALISTA_JR_DB_SEU_NOME
    GRANT SELECT ON ALL TABLES IN SCHEMA DB_SEU_NOME.raw_customer TO ROLE ANALISTA_JR_DB_SEU_NOME
    GRANT SELECT ON ALL TABLES IN SCHEMA DB_SEU_NOME.raw_pos TO ROLE ANALISTA_JR_DB_SEU_NOME
    GRANT SELECT ON ALL VIEWS IN SCHEMA DB_SEU_NOME.analytics TO ROLE ANALISTA_JR_DB_SEU_NOME
end;
    SET my_user_var  = CURRENT_USER();
    GRANT ROLE ANALISTA_JR TO USER identifier($my_user_var);

   
--Vamos explorar dados de fidelidade de clientes
USE ROLE ANALISTA_JR_DB_SEU_NOME

/*atualizar atualizar atualizar*/
/*atualizar atualizar atualizar*/
USE DATABASE DB_SEU_NOME;
/*atualizar atualizar atualizar*/
/*atualizar atualizar atualizar*/


--Dados Sensiveis sobre meus clientes
SELECT
    cl.customer_id,
    cl.first_name,
    cl.last_name,
    cl.e_mail,
    cl.phone_number,
    cl.city,
    cl.country,
    cl.sign_up_date,
    cl.birthday_date
FROM raw_customer.customer_loyalty cl 
SAMPLE (1000 ROWS);


    
/*MASCARAMENTO DE DADOS - COLUNA*/
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE MASKING POLICY PUBLIC.MASK_DADO_SENSIVEL AS (val STRING) RETURNS STRING ->
        CASE 
            WHEN CURRENT_ROLE() IN ('SYSADMIN', 'ACCOUNTADMIN') THEN val
        ELSE '**Dado Mascarado**'
    END;

CREATE OR REPLACE TAG PUBLIC.DADO_SENSIVEL WITH COMMENT = 'DADOS SENSIVEIS';

ALTER TAG DADO_SENSIVEL SET MASKING POLICY PUBLIC.MASK_DADO_SENSIVEL;

ALTER TABLE raw_customer.customer_loyalty MODIFY COLUMN e_mail SET TAG PUBLIC.DADO_SENSIVEL = 'Endereco de Email';





--Validando Políticas de Mascaramento com perfil Restrito
USE ROLE ANALISTA_JR_DB_SEU_NOME

SELECT
    cl.customer_id,
    cl.first_name,
    cl.last_name,
    cl.phone_number,
    cl.e_mail,
    cl.birthday_date,
    cl.city,
    cl.country, 
    cl.gender
FROM raw_customer.customer_loyalty cl;


--Validando Políticas de Mascaramento com perfil Completo
USE ROLE accountadmin;

SELECT
    cl.customer_id,
    cl.first_name,
    cl.last_name,
    cl.phone_number,
    cl.e_mail,
    cl.birthday_date,
    cl.city,
    cl.country
FROM raw_customer.customer_loyalty cl;

    
/*POLITICAS DE ACESSO A LINHA*/

USE ROLE accountadmin;

CREATE OR REPLACE TABLE PUBLIC.row_policy_map
    (role STRING, cidade STRING);
    

INSERT INTO PUBLIC.row_policy_map
    VALUES ('ANALISTA_JR_DB_SEU_NOME','Rio de Janeiro'); 

        
        
CREATE OR REPLACE ROW ACCESS POLICY PUBLIC.customer_city_row_policy
    AS (city STRING) RETURNS BOOLEAN ->
       CURRENT_ROLE() IN ('ACCOUNTADMIN','SYSADMIN') -- Perfis que podem ler todos os dados
        OR EXISTS 
            (
            SELECT rp.role
                FROM PUBLIC.row_policy_map rp
            WHERE 1=1
                AND rp.role = CURRENT_ROLE()
                AND rp.cidade = city
            );
            

--APLICA POLITICA
ALTER TABLE raw_customer.customer_loyalty ADD ROW ACCESS POLICY public.customer_city_row_policy ON (city);
    
--Testar com diferentes perfis     
USE ROLE ANALISTA_JR_DB_SEU_NOME

SELECT
    cl.customer_id,
    cl.first_name,
    cl.last_name,
    cl.city,
    cl.marital_status,
    DATEDIFF(year, cl.birthday_date, CURRENT_DATE()) AS age
FROM raw_customer.customer_loyalty cl SAMPLE (10000 ROWS)
GROUP BY cl.customer_id, cl.first_name, cl.last_name, cl.city, cl.marital_status, age;

select  city, count(*) from raw_customer.customer_loyalty group by city;

--E se for um usuário Admin?
USE ROLE accountadmin;

SELECT
    cl.customer_id,
    cl.first_name,
    cl.last_name,
    cl.city,
    cl.marital_status,
    DATEDIFF(year, cl.birthday_date, CURRENT_DATE()) AS age
FROM raw_customer.customer_loyalty cl SAMPLE (10000 ROWS)
GROUP BY cl.customer_id, cl.first_name, cl.last_name, cl.city, cl.marital_status, age;







--PARA TREINAR

--Alem das políticas de acesso, existem políticas de Agregação

/*POLITICAS DE AGREGAÇÃO
Politica de privacidade que permite que apenas queries que agreguem um determinado número de linhas
possam ser executadas em um objeto*/

USE ROLE accountadmin;

CREATE OR REPLACE AGGREGATION POLICY public.tasty_order_test_aggregation_policy
  AS () RETURNS AGGREGATION_CONSTRAINT ->
    CASE
      WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN','SYSADMIN')
      THEN NO_AGGREGATION_CONSTRAINT()  
      ELSE AGGREGATION_CONSTRAINT(MIN_GROUP_SIZE => 200) --mínimo de 1000 linhas
    END;

ALTER TABLE raw_pos.order_header SET AGGREGATION POLICY public.tasty_order_test_aggregation_policy;
--ALTER TABLE raw_pos.order_header unSET AGGREGATION POLICY ;

--vamos validar
USE ROLE ANALISTA_JR_DB_SEU_NOME
SELECT TOP 10 * FROM raw_pos.order_header;
SELECT TOP 5000 * FROM raw_pos.order_header;


SELECT 
cl.postal_code,
    cl.city,
    COUNT(oh.order_id) AS count_order,
    SUM(oh.order_amount) AS order_total
FROM raw_pos.order_header oh
JOIN raw_customer.customer_loyalty cl
    ON oh.customer_id = cl.customer_id
GROUP BY ALL
ORDER BY order_total DESC;

--Validação da mesma query, mas com outro perfil
use role accountadmin;
SELECT 
    cl.postal_code,
    cl.city,
    COUNT(oh.order_id) AS count_order,
    SUM(oh.order_amount) AS order_total
FROM raw_pos.order_header oh
JOIN raw_customer.customer_loyalty cl
    ON oh.customer_id = cl.customer_id
where city = 'Tokyo'
GROUP BY ALL
ORDER BY order_total DESC;


/*POLITICAS DE PROJEÇÃO
Permitem limitar o acesso de uma coluna na cláusula SELECT, mas mantem a possíbilidade na cláusula WHERE*/
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE PROJECTION POLICY public.tasty_customer_test_projection_policy
  AS () RETURNS PROJECTION_CONSTRAINT -> 
  CASE
    WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN','SYSADMIN')
    THEN PROJECTION_CONSTRAINT(ALLOW => true)
    ELSE PROJECTION_CONSTRAINT(ALLOW => false)
  END;

--Aplicar na coluna POSTAL_CODE
ALTER TABLE raw_customer.customer_loyalty 
    MODIFY COLUMN POSTAL_CODE
SET PROJECTION POLICY public.tasty_customer_test_projection_policy;

USE ROLE ANALISTA_JR_DB_SEU_NOME
SELECT TOP 100 * FROM raw_customer.customer_loyalty;
SELECT CUSTOMER_ID, PREFERRED_LANGUAGE, SIGN_UP_DATE FROM raw_customer.customer_loyalty WHERE postal_code = '144-0000';



/*SENSITIVE DATA CLASSIFICATION
*/
USE ROLE accountadmin;

--Usamos a função SYSTEM$CLASSIFY para aplicar as tags apropriadas
CALL SYSTEM$CLASSIFY('raw_customer.customer_loyalty', {'auto_tag': true});

SELECT * FROM TABLE(information_schema.tag_references_all_columns('raw_customer.customer_loyalty','table'));

/*CUSTOM SENSITIVE DATA CLASSIFICATION
*/
--Vamos aplicar regras de reconhecimento no campo PLACEKEY 
SELECT 
    TOP 10 *
FROM raw_pos.location
WHERE city = 'London';

USE ROLE accountadmin;

CREATE OR REPLACE SCHEMA classifiers;

--Agora criaremos nosso classificador para um padrão de dado identificavel como o placekey
CREATE OR REPLACE snowflake.data_privacy.custom_classifier classifiers.placekey();


--Qual a regra que deve ser avaliada?
SELECT 
    placekey
FROM raw_pos.location
WHERE placekey REGEXP('^[a-zA-Z0-9\d]{3}-[a-zA-Z0-9\d]{3,4}@[a-zA-Z0-9\d]{3}-[a-zA-Z0-9\d]{3}-.*$');


--Agora aplicamos a REGREX a nossa função de classificação
CALL placekey!ADD_REGEX(
  'PLACEKEY', -- semantic category
  'IDENTIFIER', -- privacy category
  '^[a-zA-Z0-9\d]{3}-[a-zA-Z0-9\d]{3,4}@[a-zA-Z0-9\d]{3}-[a-zA-Z0-9\d]{3}-.*$', -- regex expression
  'PLACEKEY*', --column name regex
  'Add a regex to identify Placekey' -- description
);


--Aplicar Classificação em nossa tabelas
CALL SYSTEM$CLASSIFY('raw_pos.location', {'custom_classifiers': ['placekey'], 'auto_tag':true});


-- to finish, let's confirm our Placekey column was successfully tagged
SELECT 
    tag_name,
    level, 
    tag_value,
    column_name
FROM TABLE(information_schema.tag_references_all_columns('raw_pos.location','table'))
WHERE tag_value = 'PLACEKEY';


/*DATA QUALITY MONITORING
DMF (Data Metric Functions): permite criar regras de qualidade para entender melhor os dados*/

--Métrica para contabilizar emails invalidos
CREATE OR REPLACE DATA METRIC FUNCTION public.invalid_email_count(iec TABLE(iec_c1 STRING))
RETURNS NUMBER 
    AS
'SELECT COUNT_IF(FALSE = (iec_c1 regexp ''^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$'')) FROM iec';

GRANT ALL ON FUNCTION public.invalid_email_count(TABLE(STRING)) TO ROLE public;

SELECT invalid_email_count(SELECT e_mail FROM raw_customer.customer_loyalty) AS invalid_email_count;

--Definiremos uma periodicidade para executar a avaliação das métricas
--Opções: Cron, Minuto ou Trigger_on_changes
ALTER TABLE raw_customer.customer_loyalty  SET data_metric_schedule = 'TRIGGER_ON_CHANGES';

--Aplicar métrica a colunas específicas: Duplicidade e validade e-mail
ALTER TABLE raw_customer.customer_loyalty ADD DATA METRIC FUNCTION snowflake.core.duplicate_count ON (e_mail);
ALTER TABLE raw_customer.customer_loyalty ADD DATA METRIC FUNCTION invalid_email_count ON (e_mail);

--Para simular alteraçÕes na tabela, vamos inserir novos registros
INSERT INTO raw_customer.customer_loyalty (customer_id, e_mail) VALUES
    (0000001, 'invalidemail@com'), (0000002, 'invalidemail@com') , (0000003, 'invalidemail@com'),
    (0000004, 'invalidemaildotcom') , (0000005, 'invalidemaildotcom') , (0000006, 'invalidemaildotcom');

--Validar monitoramento da qualidade dos dados
--Pode haver latencia de alguns minutos
SELECT 
    change_commit_time,
    measurement_time,
    table_schema,
    table_name,
    metric_name,
    value
FROM snowflake.local.data_quality_monitoring_results
WHERE table_database = 'INTROSNOWFLAKE_PROD'
ORDER BY change_commit_time DESC;

--Uma vez configurado, alertas podem ser definidos



//RESET

USE ROLE accountadmin;

DROP ROLE IF EXISTS ANALISTA_JR_DB_SEU_NOME

-- unset our Masking Policies
ALTER TAG PII unSET MASKING POLICY PUBLIC.MASK_DADO_SENSIVEL;
DROP TAG PUBLIC.PII ;
drop MASKING POLICY PUBLIC.MASK_DADO_SENSIVEL;

ALTER TABLE raw_customer.customer_loyalty drop ROW ACCESS POLICY public.customer_city_row_policy;

DROP ROW ACCESS POLICY PUBLIC.customer_city_row_policy;
            


-- unset our Aggregation Policy
-->ALTER TABLE raw_pos.order_header UNSET AGGREGATION POLICY;

-- remove our Projection Policy
-->ALTER TABLE raw_customer.customer_loyalty MODIFY COLUMN postal_code UNSET PROJECTION POLICY;

-- unset the System Tags
--> customer_loyalty
ALTER TABLE raw_customer.customer_loyalty MODIFY
    COLUMN first_name UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category,
    COLUMN last_name UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category,
    COLUMN e_mail UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category,
    COLUMN city UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category,
    COLUMN country UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category,
    COLUMN gender UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category,
    COLUMN marital_status UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category,
    COLUMN birthday_date UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category,
    COLUMN phone_number UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category,
    COLUMN postal_code UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category;

--> franchise
ALTER TABLE raw_pos.franchise MODIFY
    COLUMN first_name UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category,
    COLUMN last_name UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category,
    COLUMN e_mail UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category,
    COLUMN phone_number UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category,
    COLUMN city UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category,
    COLUMN country UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category;

--> menu
ALTER TABLE raw_pos.menu MODIFY
    COLUMN menu_item_name UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category;

--> location
ALTER TABLE raw_pos.location MODIFY
    COLUMN placekey UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category,
    COLUMN city UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category,
    COLUMN iso_country_code UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category,
    COLUMN country UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category;    

--> truck
ALTER TABLE raw_pos.truck MODIFY
    COLUMN primary_city UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category,
    COLUMN country UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category,
    COLUMN iso_country_code UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category;   

--> country
ALTER TABLE raw_pos.country MODIFY
    COLUMN country UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category,
    COLUMN iso_country UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category,
    COLUMN city UNSET TAG snowflake.core.privacy_category, snowflake.core.semantic_category;  

-- drop Custom Placekey Classifier
-->DROP snowflake.data_privacy.custom_classifier classifiers.placekey;

-- unset Data Metric Schedule
ALTER TABLE raw_customer.customer_loyalty 
    UNSET data_metric_schedule;

-- remove Duplicate Count DMF
--ALTER TABLE raw_customer.customer_loyalty DROP DATA METRIC FUNCTION snowflake.core.duplicate_count ON (e_mail);

-- remove Invalid Email Count DMF
--ALTER TABLE raw_customer.customer_loyalty DROP DATA METRIC FUNCTION invalid_email_count ON (e_mail);

-- drop Tags, Governance and Classifiers Schemas (including everything within)
DROP SCHEMA IF EXISTS tags;
DROP SCHEMA IF EXISTS governance;
DROP SCHEMA IF EXISTS classifiers;

-- remove test Insert records
DELETE FROM raw_customer.customer_loyalty WHERE customer_id IN (000001, 000002, 000003, 000004, 000005, 000006);


