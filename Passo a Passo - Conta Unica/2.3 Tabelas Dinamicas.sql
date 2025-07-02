
/*atualizar atualizar atualizar*/
/*atualizar atualizar atualizar*/
DB_SEU_NOME para DB_SEU_NOME;
/*atualizar atualizar atualizar*/
/*atualizar atualizar atualizar*/

USE ROLE ACCOUNTADMIN;
USE DATABASE DB_SEU_NOME;
USE WAREHOUSE WH_DB_SEU_NOME;

CREATE OR REPLACE SCHEMA TBD;
USE SCHEMA TBD;

/*
Tabelas dinamicas são objetos declarativos, que te permitem criar um pipeline inteiro através de um SQL
*/


CREATE OR REPLACE DYNAMIC TABLE RAW_CLIENTES
    LAG = downstream
    WAREHOUSE = COMPUTE_WH
AS
SELECT 
     1 as coluna
from PUBLIC.CLIENTES
;


CREATE OR REPLACE  DYNAMIC TABLE TabelaSILVER_clientes
    LAG = downstream
    WAREHOUSE = COMPUTE_WH
AS
SELECT 
     1 as coluna
from RAW_CLIENTES
;


CREATE OR REPLACE  DYNAMIC TABLE TabelaSILVER_Pacientes
    LAG = downstream
    WAREHOUSE = COMPUTE_WH
AS
SELECT 
     1 as coluna
from RAW_CLIENTES
;


CREATE OR REPLACE  DYNAMIC TABLE TabelaGold_Contagem
    LAG = '10 minutes'
    WAREHOUSE = COMPUTE_WH
AS
SELECT 
     1 as coluna
from TabelaSILVER_Pacientes
;

CREATE OR REPLACE  DYNAMIC TABLE TabelaGold_Consolidado
    LAG = '999 minutes'
    WAREHOUSE = COMPUTE_WH
AS
SELECT 
     1 as coluna
from TabelaSILVER_Pacientes
;

