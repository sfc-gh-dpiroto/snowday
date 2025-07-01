
-- first we must set our Role, Warehouse and Database context
USE ROLE tb_data_engineer;
USE WAREHOUSE tb_de_wh;
USE DATABASE tb_101;


SELECT TOP 10
    truck_brand_name,
    menu_type,
    menu_item_name,
    menu_item_health_metrics_obj
FROM raw_pos.menu;



--> Podemos acessar os objetos no Json de diferentes formas:
SELECT
    m.menu_item_name,
    m.menu_item_health_metrics_obj['menu_item_id'] AS menu_item_id,
    obj.value['ingredients']::ARRAY AS ingredients
FROM raw_pos.menu m,
    LATERAL FLATTEN (input => m.menu_item_health_metrics_obj:menu_item_health_metrics) obj
ORDER BY menu_item_id;

/**
     Array: Um ARRAY do Snowflake é semelhante a um array em muitas outras linguagens de programação.
      Um ARRAY contém 0 ou mais pedaços de dados. Cada elemento é acessado especificando
      sua posição no array.
    **/

/*--
 Para concluir nosso processamento Semi-Estruturado (*Semi-Structured processing*), vamos extrair as Colunas Dietéticas (*Dietary Columns*) restantes
 usando tanto a Notação de Ponto (*Dot Notation*) quanto a Notação de Colchetes (*Bracket Notation*) juntamente com o Array de Ingredientes (*Ingredients Array*).
--*/

--> Notação de Ponto (*Dot Notation*) e LATERAL FLATTEN
SELECT
    m.menu_item_health_metrics_obj:menu_item_id AS menu_item_id,
    m.menu_item_name,
    obj.value:"ingredients"::VARIANT AS ingredients,
    obj.value:"is_healthy_flag"::VARCHAR(1) AS is_healthy_flag,
    obj.value:"is_gluten_free_flag"::VARCHAR(1) AS is_gluten_free_flag,
    obj.value:"is_dairy_free_flag"::VARCHAR(1) AS is_dairy_free_flag,
    obj.value:"is_nut_free_flag"::VARCHAR(1) AS is_nut_free_flag
FROM raw_pos.menu m,
    LATERAL FLATTEN (input => m.menu_item_health_metrics_obj:menu_item_health_metrics) obj;


--vamos criar uma view para abstrair a complexidade da consulta
CREATE OR REPLACE VIEW harmonized.menu_v
    AS
SELECT
    m.menu_id,
    m.menu_type_id,
    m.menu_type,
    m.truck_brand_name,
    m.menu_item_health_metrics_obj:menu_item_id::integer AS menu_item_id,
    m.menu_item_name,
    m.item_category,
    m.item_subcategory,
    m.cost_of_goods_usd,
    m.sale_price_usd,
    obj.value:"ingredients"::VARIANT AS ingredients,
    obj.value:"is_healthy_flag"::VARCHAR(1) AS is_healthy_flag,
    obj.value:"is_gluten_free_flag"::VARCHAR(1) AS is_gluten_free_flag,
    obj.value:"is_dairy_free_flag"::VARCHAR(1) AS is_dairy_free_flag,
    obj.value:"is_nut_free_flag"::VARCHAR(1) AS is_nut_free_flag
FROM raw_pos.menu m,
    LATERAL FLATTEN (input => m.menu_item_health_metrics_obj:menu_item_health_metrics) obj;

    

--Buscas em Arrays, sem necessidade de tabular o dado.
SELECT
    m.menu_item_id,
    m.menu_item_name,
    m.ingredients
FROM harmonized.menu_v m
WHERE ARRAY_CONTAINS('Lettuce'::VARIANT, m.ingredients);

