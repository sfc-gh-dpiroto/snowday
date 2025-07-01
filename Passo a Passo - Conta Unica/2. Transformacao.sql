/*----------------------------------------------------------------------------------
Passo 1 - Clonagem Zero Copy (*Zero Copy Cloning*)

Como parte da Análise de Frota da Tasty Bytes (*Tasty Bytes Fleet Analysis*), nosso Desenvolvedor (*Developer*) foi encarregado de criar
e atualizar uma nova coluna Tipo de Caminhão (*Truck Type*) na tabela de Caminhões (*Truck table*) da camada Bruta (*Raw layer*) que combina
o Ano (*Year*), Fabricante (*Make*) e Modelo (*Model*).

Nesta etapa, primeiro vamos percorrer a configuração de um ambiente de Desenvolvimento (*Development environment*)
usando a Clonagem Zero Copy (*Zero Copy Cloning*) do Snowflake para que este desenvolvimento seja concluído e testado
antes de ser implementado em produção (*production*).
----------------------------------------------------------------------------------*/

-- antes de começarmos, vamos definir nosso contexto de Função (*Role*) e Depósito (*Warehouse*)
USE ROLE tb_dev;


/*atualizar atualizar atualizar*/
/*atualizar atualizar atualizar*/
USE DATABASE DB_SEU_NOME;
/*atualizar atualizar atualizar*/
/*atualizar atualizar atualizar*/


-- para garantir que o desenvolvimento da nossa nova Coluna (*Column*) não afete a produção (*production*),
-- vamos primeiro criar uma cópia instantânea (*snapshot copy*) da tabela Truck (*Truck table*) usando o Clone
CREATE OR REPLACE TABLE raw_pos.truck_dev CLONE raw_pos.truck;

/**
        Clonagem Zero Cópia (*Zero Copy Cloning*): Cria uma cópia de um banco de dados (*database*), esquema (*schema*) ou tabela (*table*). Um instantâneo (*snapshot*) dos dados presentes no
         objeto de origem (*source object*) é tirado quando o clone é criado e é disponibilizado para o objeto clonado (*cloned object*).

         O objeto clonado é gravável e independente da origem do clone. Ou seja, alterações feitas
         tanto no objeto de origem quanto no objeto clonado não fazem parte um do outro. Clonar um banco de dados
         clonará todos os esquemas e tabelas dentro desse banco de dados. Clonar um esquema clonará todas as
         tabelas nesse esquema.
      **/

USE WAREHOUSE tb_dev_wh;


-- com nosso Clone Zero Cópia (*Zero Copy Clone*) criado, vamos consultar o que precisaremos combinar para nossa nova coluna Tipo de Caminhão (*Truck Type*)
SELECT
    t.truck_id,
    t.year,
    t.make,
    t.model
FROM raw_pos.truck_dev t
ORDER BY t.truck_id;


/*----------------------------------------------------------------------------------
Passo 3 - Adicionando e Atualizando uma Coluna em uma Tabela

Nesta etapa, vamos agora Adicionar e Atualizar uma coluna Tipo de Caminhão (*Truck Type*)
na Tabela de Caminhão de Desenvolvimento (*Development Truck Table*) que criamos anteriormente, ao mesmo tempo em que corrigimos
o erro de digitação (*typo*) no campo Fabricante (*Make*).
----------------------------------------------------------------------------------*/

-- para começar, vamos corrigir o erro de digitação que notamos na coluna Fabricante (*Make*)
UPDATE raw_pos.truck_dev 
    SET make = 'Ford' WHERE make = 'Ford_';


-- agora, vamos construir a consulta (*query*) para concatenar (*concatenate*) as colunas que formarão nosso Tipo de Caminhão (*Truck Type*)
SELECT
    truck_id,
    year,
    make,
    model,
    CONCAT(year,' ',make,' ',REPLACE(model,' ','_')) AS truck_type
FROM raw_pos.truck_dev;


-- vamos agora Adicionar a Coluna Tipo de Caminhão (*Truck Type Column*) à tabela
ALTER TABLE raw_pos.truck_dev 
    ADD COLUMN truck_type VARCHAR(100);


-- com nossa coluna vazia (*empty column*) no lugar, podemos agora executar a instrução de Atualização (*Update statement*) para popular cada linha
UPDATE raw_pos.truck_dev
    SET truck_type =  CONCAT(year,make,' ',REPLACE(model,' ','_'));


-- com 450 linhas atualizadas com sucesso, vamos validar nosso trabalho
SELECT
    truck_id,
    year,
    truck_type
FROM raw_pos.truck_dev
ORDER BY truck_id;


/*----------------------------------------------------------------------------------
Passo 3 - Viagem no Tempo (*Time-Travel*) para Restauração de Tabela

Ah, não! Cometemos um erro na instrução de Atualização (*Update statement*) anteriormente e esquecemos de adicionar um espaço
entre Ano (*Year*) e Fabricante (*Make*). Felizmente, podemos usar a Viagem no Tempo (*Time Travel*) para reverter nossa tabela
ao estado em que estava depois que corrigimos o erro de ortografia, para que possamos corrigir nosso trabalho.

A Viagem no Tempo (*Time-Travel*) permite acessar dados que foram alterados ou excluídos a qualquer momento
em até 90 dias. Ela serve como uma ferramenta poderosa para executar as seguintes tarefas:
  - Restaurar objetos de dados que foram alterados ou excluídos incorretamente.
  - Duplicar e fazer backup de dados de pontos-chave do passado.
  - Analisar o uso/manipulação de dados em períodos de tempo especificados.
----------------------------------------------------------------------------------*/

-- primeiro, vamos examinar todas as instruções de Atualização (*Update statements*) em nossa Tabela de Desenvolvimento 
-- usando a função de Histórico de Consultas (*Query History*)
SELECT
    query_id,
    query_text,
    user_name,
    query_type,
    start_time
FROM TABLE(information_schema.query_history())
WHERE 1=1
    AND query_type = 'UPDATE'
    AND query_text LIKE '%raw_pos.truck_dev%'
ORDER BY start_time DESC;


SET query_id =
    (
    SELECT TOP 1
        query_id
    FROM TABLE(information_schema.query_history())
    WHERE 1=1
        AND query_type = 'UPDATE'
        AND query_text LIKE '%SET truck_type =%'
    ORDER BY start_time DESC
    );

/**
    A Viagem no Tempo (*Time-Travel*) oferece muitas opções de instrução diferentes, incluindo:
        • At, Before, Timestamp, Offset e Statement

    Para nossa demonstração, usaremos Statement, pois temos o ID da Consulta (*Query ID*) da nossa instrução de Atualização (*Update statement*) incorreta
    e queremos reverter nossa tabela para o estado em que estava antes da execução dela.
    **/

-- agora podemos aproveitar a Viagem no Tempo (*Time Travel*) e nossa Variável (*Variable*) para observar o estado da Tabela de Desenvolvimento (*Development Table*) para o qual estaremos revertendo
SELECT 
    truck_id,
    make,
    truck_type
FROM raw_pos.truck_dev
BEFORE(STATEMENT => $query_id)
ORDER BY truck_id;


-- using Time Travel and Create or Replace Table, let's restore our Development Table
CREATE OR REPLACE TABLE raw_pos.truck_dev
    AS
SELECT * FROM raw_pos.truck_dev
BEFORE(STATEMENT => $query_id); -- revert to before a specified Query ID ran


--to conclude, let's run the correct Update statement 
UPDATE raw_pos.truck_dev t
    SET truck_type = CONCAT(t.year,' ',t.make,' ',REPLACE(t.model,' ','_'));

select truck_type from raw_pos.truck_dev;

/*----------------------------------------------------------------------------------
Passo 4 - Troca (*Swap*), Exclusão (*Drop*) e Restauração (*Undrop*) de Tabela

Com base em nossos esforços anteriores, atendemos aos requisitos que nos foram dados e,
para concluir nossa tarefa, precisamos mover nosso Desenvolvimento (*Development*) para Produção (*Production*).

Nesta etapa, trocaremos (*swap*) nossa tabela de Caminhão de Desenvolvimento (*Development Truck table*) com o que está atualmente
disponível em Produção.
----------------------------------------------------------------------------------*/

-- nossa função (*role*) Accountadmin agora fará a Troca (*Swap*) da nossa Tabela de Desenvolvimento (*Development Table*) com a de Produção
USE ROLE accountadmin;

ALTER TABLE raw_pos.truck_dev 
    SWAP WITH raw_pos.truck;


-- let's confirm the production Truck table has the new column in place
SELECT
    t.truck_id,
    t.truck_type
FROM raw_pos.truck t
WHERE t.make = 'Ford';


-- parece ótimo, vamos agora excluir (*drop*) a Tabela de Desenvolvimento (*Development Table*)
DROP TABLE raw_pos.truck;


-- cometemos um erro! aquela era a versão de produção (*production version*) da tabela!
-- vamos rapidamente usar outro recurso dependente da Viagem no Tempo (*Time Travel*) e restaurá-la (*Undrop*)
UNDROP TABLE raw_pos.truck;


-- com a tabela de Produção (*Production table*) restaurada, podemos agora excluir (*drop*) corretamente a Tabela de Desenvolvimento (*Development Table*)
DROP TABLE raw_pos.truck_dev;


/*----------------------------------------------------------------------------------
/* Plano de Execução  */
----------------------------------------------------------------------------------*/

    SELECT 
        o.customer_id,
        CONCAT(clm.first_name, ' ', clm.last_name) AS name,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(o.price) AS total_sales
    FROM analytics.orders_v o
    JOIN analytics.customer_loyalty_metrics_v clm
        ON o.customer_id = clm.customer_id
    GROUP BY o.customer_id, name
    ORDER BY order_count DESC;
    

/*----------------------------------------------------------------------------------
/* Vamos testar com mais volume de dados */
----------------------------------------------------------------------------------*/


--Clone Objeto Gigante
select count(*) from raw_pos.order_detail;

--criação de clone
create table raw_pos.order_detail_clone clone raw_pos.order_detail;

--vamos validar a quantidade de dados na tabela Clonada
select count(*) from raw_pos.order_detail_clone;
select * from raw_pos.order_detail_clone limit 10;

--alterações no clone
ALTER WAREHOUSE tb_test_wh SET warehouse_size = 'XXLarge';
update raw_pos.order_detail_clone set unit_price = 0;

--Alterações devidamente aplicadas no clone?
select unit_price, count(*) from raw_pos.order_detail_clone 
group by all;

--e na tabela original?
select unit_price, count(*) from raw_pos.order_detail
group by all;

--vamos voltar ao poder de processamento original
ALTER WAREHOUSE tb_test_wh SET warehouse_size = 'XSMALL';


/*----------------------------------------------------------------------------------
 Reset Scripts 
 
  Run the scripts below to reset your account to the state required to re-run
  this vignette.

USE ROLE accountadmin;

-- revert Ford to Ford_
UPDATE raw_pos.truck SET make = 'Ford_' WHERE make = 'Ford';

-- remove Truck Type column
ALTER TABLE raw_pos.truck DROP COLUMN IF EXISTS truck_type;

-- unset SQL Variable
UNSET query_id;

-- unset Query Tag
ALTER SESSION UNSET query_tag;

----------------------------------------------------------------------------------*/