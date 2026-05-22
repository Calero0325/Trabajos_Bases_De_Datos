SET serveroutput ON; 


/**
--- FUNCIONES

- pueden utilizarse en sentencias SQL de manipulacion de datos (select , update, insert delete)


Prefijo de la funcion para todo!!!!!!
fn_...(funcion)
pck_.... (paquete)


OR REPLACE = permite sobreescribir una funcion exixtente 

TO_CHAR = entra un numero  y sale en dato 
ejemplo 
select to_char(4545)  -> '4545'


CREATE OR REPLACE PACKAGE BODY pck_xxxx
.....

procedure Calcular_nomina


end;

--- una funcion retorna un solo valor 
--- logica que devuelve parametros 


triggers(disparadores)

- bloque PL/SQL asociado a una tabla , que se ejecuta como consecuencia de una determinada instruccion sql 



*/


------ retonar un valor caracter , y recibe el nombre 
---saludar a alguien

CREATE OR REPLACE FUNCTION fn_saludar (
    vv_nombre VARCHAR2
) RETURN VARCHAR2
IS
vv_result varchar2(200);
BEGIN
vv_result := 'Hola, usted se llama ';
        dbms_output.put_line ( vv_result || vv_nombre );
        RETURN vv_result || vv_nombre ;
    END fn_saludar;
/ 

DECLARE
si VARCHAR2(200);
BEGIN 
si :=fn_saludar('Yiomar Chaparro');
END;
/

------------------------------------------------------------------
