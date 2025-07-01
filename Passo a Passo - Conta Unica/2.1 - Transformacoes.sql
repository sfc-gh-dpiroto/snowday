USE WAREHOUSE compute_wh;

/*atualizar atualizar atualizar*/
/*atualizar atualizar atualizar*/
USE DATABASE DB_SEU_NOME;
/*atualizar atualizar atualizar*/
/*atualizar atualizar atualizar*/

use schema public;


--Gerador de Dados Sintéticos
create or replace function public.gen_cust_info(num_records number)
returns table (custid number(10), cname varchar(100), estado varchar(100), cpf varchar(12), SaldoDevedor number(10,2))
language python
runtime_version=3.10
handler='CustTab'
packages = ('Faker')
as $$
from faker import Faker
import random

fake = Faker('pt_BR')
# Generate a list of customers  

class CustTab:
    # Generate multiple customer records
    def process(self, num_records):
        customer_id = 1000 # Starting customer ID                 
        for _ in range(num_records):
            custid = customer_id + 1
            cname = fake.name()
            estado = fake.state()
            cpf = fake.cpf()
            spendlimit = round(random.uniform(50, 1000),2)
            customer_id += 1
            yield (custid,cname,estado, cpf,spendlimit)

$$;



--Cria tabela dos dados aleatórios
create or replace table CLIENTES as select * from table(public.gen_cust_info(50000)) order by 1;

select * from CLIENTES;









/*FUNCTIONS*/

--Função Usando SQL Nativo
CREATE OR REPLACE FUNCTION UDF_PRIMEIRONOME (NOME VARCHAR(30))
RETURNS VARCHAR(100) AS
$$
    select substr(NOME, 0, charindex(' ', NOME)) primeiroNome
$$
;

--Função usando Python
CREATE OR REPLACE FUNCTION udf_primeironome_python(nome VARCHAR)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.9'
HANDLER = 'get_first_name'
AS
$$
# Python code defined within the AS block
def get_first_name(full_name: str) -> str:

    if full_name is None:
        return None

    trimmed_name = full_name.strip()
    space_index = trimmed_name.find(' ') # Returns -1 if no space is found

    if space_index == -1:
        return trimmed_name
    else:
        return trimmed_name[:space_index]
$$;



--Funçao Usando JS
CREATE OR REPLACE FUNCTION udf_primeironome_js(NOME VARCHAR) -- Parameter name is NOME
RETURNS VARCHAR
LANGUAGE JAVASCRIPT
AS
$$
    if (NOME === null || typeof NOME === 'undefined') {
        return null;
    }

    var trimmedName = NOME.trim();

    var spaceIndex = trimmedName.indexOf(' '); // Returns -1 if no space is found

    if (spaceIndex === -1) {
        return trimmedName;
    } else {
        return trimmedName.substring(0, spaceIndex);
    }
$$;

--Funação Usando Java
CREATE OR REPLACE FUNCTION udf_primeironome_java(nome VARCHAR)
RETURNS VARCHAR
LANGUAGE JAVA
HANDLER='FirstNameExtractor.getFirst' -- Specifies the class and method to call
AS
$$
class FirstNameExtractor {
    public String getFirst(String fullName) {

        if (fullName == null) {
            return null;
        }

        String trimmedName = fullName.trim();
        int spaceIndex = trimmedName.indexOf(' '); 

        if (spaceIndex == -1) {

            return trimmedName;
        } else {
            return trimmedName.substring(0, spaceIndex);
        }
    }
}
$$;

--Uso da Funçoes via SQL
SELECT 
    cname,
    UDF_PRIMEIRONOME(cname) as _SQL,
    udf_primeironome_python(cname) as _Python,
    udf_primeironome_js(cname) as _JS,
    udf_primeironome_java(cname) as _Java
FROM CLIENTES;



/*PROCEDURES*/

--Procedure que copia parte dos dados de uma tabela e executa tratativas
--relevantes para o negócio.
--Procedures também podem ser em SQL, Python, Scala, JS
CREATE OR REPLACE PROCEDURE USP_FORMATA_TB()
RETURNS STRING NOT NULL
LANGUAGE SQL
EXECUTE AS CALLER
AS 
BEGIN


    CREATE OR REPLACE TABLE TB_PROC
    AS SELECT * FROM CLIENTES LIMIT 100;

    ALTER TABLE TB_PROC ADD COLUMN PRIMEIRO_NOME_PROC STRING;
    ALTER TABLE TB_PROC ADD COLUMN DT_MODIFIACAO_PROC timestamp;
    
    
    UPDATE TB_PROC 
    SET 
        PRIMEIRO_NOME_PROC = UDF_PRIMEIRONOME(cname),
        DT_MODIFIACAO_PROC = current_timestamp();

    RETURN 'Sucesso';
    
END;

--Chama Procedure
call USP_FORMATA_TB();
select * from TB_PROC ;
