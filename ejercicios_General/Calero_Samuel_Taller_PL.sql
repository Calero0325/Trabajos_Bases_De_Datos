SET SERVEROUTPUT ON;

-- ============================================================
-- TALLER AVANZADO PL/SQL — SETUP SCRIPT
-- Sistema de Liquidación de Nómina — HotelGroup S.A.
-- Nombre: Samuel Steven Calero Sanchez
-- ============================================================


-- PUNTO 1: Bloque anónimo — Liquidación individual empleado

DECLARE

cn_id CONSTANT EMPLEADOS.id_empleado%TYPE := 1001;

vv_emp EMPLEADOS%ROWTYPE;
vn_horas NUMBER;
vn_sanciones NUMBER;
vn_salario_q NUMBER;
vn_valor_hora NUMBER;
vn_recargos NUMBER := 0;
vn_bono NUMBER := 0;
vn_antiguedad NUMBER;

    CURSOR c_params IS
        SELECT MAX(CASE WHEN cod_parametro = 'SMLMV'            THEN valor_numerico END) AS smlmv,
               MAX(CASE WHEN cod_parametro = 'RET_SERVICIOS'    THEN valor_numerico END) AS ret_serv,
               MAX(CASE WHEN cod_parametro = 'RECARGO_NOCTURNO' THEN valor_numerico END) AS rec_noct,
               MAX(CASE WHEN cod_parametro = 'RECARGO_DOMINICAL'THEN valor_numerico END) AS rec_dom,
               MAX(CASE WHEN cod_parametro = 'RECARGO_NOCT_DOM' THEN valor_numerico END) AS rec_noct_dom
          FROM PARAMETROS;
    vv_params c_params%ROWTYPE;

    CURSOR c_horas(param_id NUMBER, param_quincena VARCHAR2) IS
        SELECT tipo_hora, cantidad_horas
        FROM HORAS_TRABAJADAS
        WHERE id_empleado = param_id
        AND id_quincena = param_quincena;
        
    vv_hora c_horas%ROWTYPE;

BEGIN
    -- Obtener datos del empleado
    SELECT * INTO vv_emp FROM EMPLEADOS WHERE id_empleado = cn_id;

    OPEN c_params;
    FETCH c_params INTO vv_params;
    CLOSE c_params;

    vn_antiguedad := TRUNC(MONTHS_BETWEEN(SYSDATE, vv_emp.fecha_ingreso) / 12);

    -- REGLA 1: Cálculo de salario base quincenal según tipo de contrato
    IF vv_emp.tipo_contrato = 'PLANTA' THEN
        vn_valor_hora := vv_emp.salario_base / 240;
        vn_salario_q  := vv_emp.salario_base / 2;

    ELSIF vv_emp.tipo_contrato = 'TEMPORAL' THEN
        SELECT NVL(SUM(cantidad_horas), 0)
          INTO vn_horas
          FROM HORAS_TRABAJADAS
         WHERE id_empleado = cn_id
           AND id_quincena = '2026-Q1-ENE'
           AND tipo_hora   = 'NORMAL';

        vn_valor_hora := vv_emp.salario_base;
        vn_salario_q  := vn_horas * vn_valor_hora;

    ELSE -- SERVICIOS
        vn_salario_q := (vv_emp.salario_base * (100 - vv_params.ret_serv)) / 200;
    END IF;

    -- REGLA 2: Cálculo de recargos por horas especiales
    IF vv_emp.tipo_contrato IN ('PLANTA', 'TEMPORAL') THEN
        OPEN c_horas(cn_id, '2026-Q1-ENE');
        LOOP
            FETCH c_horas INTO vv_hora;
            EXIT WHEN c_horas%NOTFOUND;

            IF vv_hora.tipo_hora = 'NOCTURNA' THEN
                vn_recargos := vn_recargos
                             + vv_hora.cantidad_horas * vn_valor_hora * (vv_params.rec_noct / 100);

            ELSIF vv_hora.tipo_hora = 'DOMINICAL' THEN
                vn_recargos := vn_recargos
                             + vv_hora.cantidad_horas * vn_valor_hora * (vv_params.rec_dom / 100);

            ELSIF vv_hora.tipo_hora = 'NOCTURNA_DOM' THEN
                vn_recargos := vn_recargos
                             + vv_hora.cantidad_horas * vn_valor_hora * (vv_params.rec_noct_dom / 100);
            END IF;
        END LOOP;
        CLOSE c_horas;
    END IF;

    -- REGLA 3: Bonificación por antigüedad (sin sanciones recientes)
    IF vv_emp.tipo_contrato IN ('PLANTA', 'TEMPORAL') THEN
        SELECT COUNT(*) INTO vn_sanciones
          FROM SANCIONES
         WHERE id_empleado   = cn_id
           AND fecha_sancion >= ADD_MONTHS(SYSDATE, -6);

        IF vn_sanciones <= 2 THEN
            IF    vn_antiguedad BETWEEN 3 AND 5   THEN vn_bono := vn_salario_q * 0.03;
            ELSIF vn_antiguedad BETWEEN 6 AND 10  THEN vn_bono := vn_salario_q * 0.06;
            ELSIF vn_antiguedad > 10 THEN vn_bono := vn_salario_q * 0.10;
            END IF;
        END IF;
    END IF;

    -- Salida del resultado
    DBMS_OUTPUT.PUT_LINE('=== LIQUIDACIÓN QUINCENAL ===');
    DBMS_OUTPUT.PUT_LINE('Empleado  : ' || vv_emp.nombre || ' (' || cn_id || ')');
    DBMS_OUTPUT.PUT_LINE('Sede      : ' || vv_emp.cod_sede);
    DBMS_OUTPUT.PUT_LINE('Contrato  : ' || vv_emp.tipo_contrato);
    DBMS_OUTPUT.PUT_LINE('Antigüedad: ' || vn_antiguedad || ' años');
    DBMS_OUTPUT.PUT_LINE('-----------------------------');
    DBMS_OUTPUT.PUT_LINE('Salario base Q : ' || TO_CHAR(vn_salario_q, '999,999,990.00'));
    DBMS_OUTPUT.PUT_LINE('Recargos       : ' || TO_CHAR(vn_recargos,  '999,999,990.00'));
    DBMS_OUTPUT.PUT_LINE('Bonificación   : ' || TO_CHAR(vn_bono,      '999,999,990.00'));
    DBMS_OUTPUT.PUT_LINE('-----------------------------');
    DBMS_OUTPUT.PUT_LINE('SUBTOTAL       : '
        || TO_CHAR(vn_salario_q + vn_recargos + vn_bono, '999,999,990.00'));
    DBMS_OUTPUT.PUT_LINE('=============================');

END;
/

-- PUNTO 2: Funciones independientes de liquidación

-- ------------------------------------------------------------
-- 2.1  fn_salario_base_q  — Regla 1
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_salario_base_q(
    param_id_empleado NUMBER,
    param_id_quincena VARCHAR2
) RETURN NUMBER IS

    vv_tipo EMPLEADOS.tipo_contrato%TYPE;
    vn_salario EMPLEADOS.salario_base%TYPE;
    vn_ret NUMBER;
    vn_horas NUMBER := 0;

BEGIN
    SELECT tipo_contrato, salario_base
      INTO vv_tipo, vn_salario
      FROM EMPLEADOS
     WHERE id_empleado = param_id_empleado;

    IF vv_tipo = 'PLANTA' THEN
        RETURN vn_salario / 2;

    ELSIF vv_tipo = 'TEMPORAL' THEN
        SELECT NVL(SUM(cantidad_horas), 0)
          INTO vn_horas
          FROM HORAS_TRABAJADAS
         WHERE id_empleado = param_id_empleado
           AND id_quincena = param_id_quincena
           AND tipo_hora   = 'NORMAL';
        RETURN vn_salario * vn_horas;

    ELSE -- SERVICIOS
        SELECT valor_numerico
          INTO vn_ret
          FROM PARAMETROS
         WHERE cod_parametro = 'RET_SERVICIOS';
        RETURN (vn_salario * (100 - vn_ret)) / 200;
    END IF;

END fn_salario_base_q;
/


-- ------------------------------------------------------------
-- 2.2  fn_recargos  — Regla 2
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_recargos(
    param_id_empleado NUMBER,
    param_id_quincena VARCHAR2
) RETURN NUMBER IS

vv_tipo EMPLEADOS.tipo_contrato%TYPE;
vn_salario EMPLEADOS.salario_base%TYPE;
vn_valor_hora NUMBER;
vn_total NUMBER := 0;
vn_rec_noct NUMBER;
vn_rec_dom NUMBER;
vn_rec_nd NUMBER;

CURSOR c_horas(param_emp NUMBER, param_quin VARCHAR2) IS
SELECT tipo_hora, cantidad_horas
FROM HORAS_TRABAJADAS
WHERE id_empleado = param_emp
AND id_quincena = param_quin
AND tipo_hora IN ('NOCTURNA', 'DOMINICAL', 'NOCTURNA_DOM');

BEGIN
    SELECT tipo_contrato, salario_base
      INTO vv_tipo, vn_salario
      FROM EMPLEADOS
     WHERE id_empleado = param_id_empleado;

    IF vv_tipo = 'SERVICIOS' THEN
        RETURN 0;
    END IF;

    SELECT MAX(CASE WHEN cod_parametro = 'RECARGO_NOCTURNO'  THEN valor_numerico END),
           MAX(CASE WHEN cod_parametro = 'RECARGO_DOMINICAL' THEN valor_numerico END),
           MAX(CASE WHEN cod_parametro = 'RECARGO_NOCT_DOM'  THEN valor_numerico END)
      INTO vn_rec_noct, vn_rec_dom, vn_rec_nd
      FROM PARAMETROS;

    vn_valor_hora := CASE vv_tipo 
        WHEN 'PLANTA' 
             THEN vn_salario / 240
                  ELSE vn_salario
    END;

    FOR vv_hora IN c_horas(param_id_empleado, param_id_quincena) LOOP
        IF    vv_hora.tipo_hora = 'NOCTURNA'     THEN
            vn_total := vn_total + vv_hora.cantidad_horas * vn_valor_hora * (vn_rec_noct / 100);
        ELSIF vv_hora.tipo_hora = 'DOMINICAL'    THEN
            vn_total := vn_total + vv_hora.cantidad_horas * vn_valor_hora * (vn_rec_dom  / 100);
        ELSIF vv_hora.tipo_hora = 'NOCTURNA_DOM' THEN
            vn_total := vn_total + vv_hora.cantidad_horas * vn_valor_hora * (vn_rec_nd   / 100);
        END IF;
    END LOOP;

    RETURN NVL(vn_total, 0);

END fn_recargos;
/


-- ------------------------------------------------------------
-- 2.3  fn_bonificacion  — Regla 3
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_bonificacion(
    param_id_empleado NUMBER,
    param_id_quincena VARCHAR2
) RETURN NUMBER IS

vv_tipo EMPLEADOS.tipo_contrato%TYPE;
vd_ingreso EMPLEADOS.fecha_ingreso%TYPE;
vn_sanciones NUMBER;
vn_antiguedad NUMBER;
vn_pct NUMBER := 0;

BEGIN

    SELECT tipo_contrato, fecha_ingreso
      INTO vv_tipo, vd_ingreso
      FROM EMPLEADOS
     WHERE id_empleado = param_id_empleado;

    IF vv_tipo = 'SERVICIOS' THEN
        RETURN 0;
    END IF;

    SELECT COUNT(*)
      INTO vn_sanciones
      FROM SANCIONES
     WHERE id_empleado   = param_id_empleado
       AND fecha_sancion >= ADD_MONTHS(SYSDATE, -6);

    IF vn_sanciones > 2 THEN
        RETURN 0;
    END IF;

    vn_antiguedad := TRUNC(MONTHS_BETWEEN(SYSDATE, vd_ingreso) / 12);

    IF    vn_antiguedad BETWEEN 3 AND 5   THEN vn_pct := 3;
    ELSIF vn_antiguedad BETWEEN 6 AND 10  THEN vn_pct := 6;
    ELSIF vn_antiguedad > 10              THEN vn_pct := 10;
    END IF;

    RETURN ROUND(fn_salario_base_q(param_id_empleado, param_id_quincena) * vn_pct / 100, 2);

END fn_bonificacion;
/



-- 2.4  fn_bruto  — Reglas 4, 5 y 6 

CREATE OR REPLACE FUNCTION fn_bruto(
    param_id_empleado NUMBER,
    param_id_quincena VARCHAR2
) RETURN NUMBER IS

vv_tipo EMPLEADOS.tipo_contrato%TYPE;
vn_salario EMPLEADOS.salario_base%TYPE;
vv_sede EMPLEADOS.cod_sede%TYPE;
vn_aux_transp NUMBER := 0;
vn_bono_sede  NUMBER := 0;
vn_smlmv NUMBER;
vn_aux_mens NUMBER;
vn_horas_norm NUMBER := 0;
vn_sal_mens NUMBER;

BEGIN
    SELECT tipo_contrato, salario_base, cod_sede
      INTO vv_tipo, vn_salario, vv_sede
      FROM EMPLEADOS
     WHERE id_empleado = param_id_empleado;

-- Auxilio de transporte (aplica solo a PLANTA y TEMPORAL)
    IF vv_tipo != 'SERVICIOS' THEN
        SELECT MAX(CASE WHEN cod_parametro = 'SMLMV' THEN valor_numerico END),
               MAX(CASE WHEN cod_parametro = 'AUX_TRANSPORTE' THEN valor_numerico END)
          INTO vn_smlmv, vn_aux_mens
          FROM PARAMETROS;

        IF vv_tipo = 'TEMPORAL' THEN
            SELECT NVL(SUM(cantidad_horas), 0)
              INTO vn_horas_norm
              FROM HORAS_TRABAJADAS
             WHERE id_empleado = param_id_empleado
               AND id_quincena = param_id_quincena
               AND tipo_hora   = 'NORMAL';
            vn_sal_mens := vn_salario * vn_horas_norm * 2;
        ELSE
            vn_sal_mens := vn_salario;
        END IF;

        IF vn_sal_mens <= 2 * vn_smlmv THEN
            vn_aux_transp := vn_aux_mens / 2;
        END IF;
    END IF;

-- Bono sede Santa Marta
    IF vv_sede = 'SMA' AND vv_tipo != 'SERVICIOS' THEN
        SELECT valor_numerico
          INTO vn_bono_sede
          FROM PARAMETROS
         WHERE cod_parametro = 'BONO_CLIMA_SMA';
    END IF;

    RETURN ROUND(
        fn_salario_base_q(param_id_empleado, param_id_quincena)
        + fn_recargos (param_id_empleado, param_id_quincena)
        + fn_bonificacion(param_id_empleado, param_id_quincena)
        + vn_aux_transp
        + vn_bono_sede,
    2);

END fn_bruto;
/

-- Prueba con el empleado 1001
SELECT 'Empleado 1001 (Planta)' AS empleado,
       fn_bruto(1001, '2026-Q1-ENE') AS bruto
  FROM DUAL;
/



-- PUNTO 3: Procedimiento sp_liquidar_empleado

CREATE OR REPLACE PROCEDURE sp_liquidar_empleado(
    param_id_empleado NUMBER,
    param_id_quincena VARCHAR2
) IS

vv_estado EMPLEADOS.estado%TYPE;
vv_tipo  EMPLEADOS.tipo_contrato%TYPE;
vv_sede EMPLEADOS.cod_sede%TYPE;
vv_acepta_vol  EMPLEADOS.acepta_aporte_vol%TYPE;
vn_salario EMPLEADOS.salario_base%TYPE;
vn_ya_existe   NUMBER;

-- Devengados
vn_base_q      NUMBER;
vn_recargos    NUMBER;
vn_bonif       NUMBER;
vn_aux_transp  NUMBER := 0;
vn_bono_sede   NUMBER := 0;
vn_bruto       NUMBER;

 -- Deducciones
vn_salud NUMBER := 0;
vn_pension NUMBER := 0;
vn_fondo_sol NUMBER := 0;
vn_embargo NUMBER := 0;
vn_libranzas NUMBER := 0;
vn_aporte_vol NUMBER := 0;
vn_total_ded NUMBER;
vn_neto NUMBER;

-- Parámetros 
vn_smlmv NUMBER;
vn_aux_mens NUMBER;
vn_pct_salud NUMBER;
vn_pct_pension NUMBER;
vn_pct_fondo NUMBER;
vn_umbral NUMBER;
vn_aporte_bog NUMBER;
vn_bono_sma NUMBER;
vn_pct_emb NUMBER := 0;
vn_horas_norm NUMBER := 0;
vn_sal_mens NUMBER := 0;

BEGIN

BEGIN
SELECT estado, tipo_contrato, cod_sede, acepta_aporte_vol, salario_base
INTO vv_estado, vv_tipo, vv_sede, vv_acepta_vol, vn_salario
FROM EMPLEADOS
WHERE id_empleado = param_id_empleado;
EXCEPTION
WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20001,
        'Empleado no encontrado: ' || param_id_empleado);
END;

-- Validación: empleado activo
IF vv_estado != 'ACTIVO' THEN
    RAISE_APPLICATION_ERROR(-20002,
        'Empleado no activo: estado = ' || vv_estado);
END IF;
    
-- Validación: liquidación no duplicada
SELECT COUNT(*)
INTO vn_ya_existe
FROM LIQUIDACION
WHERE id_empleado = param_id_empleado
AND id_quincena = param_id_quincena;

IF vn_ya_existe > 0 THEN
    RAISE_APPLICATION_ERROR(-20003,
        'Liquidación ya existe para empleado ' || param_id_empleado
        || ' quincena ' || param_id_quincena);
END IF;
    
-- Cargar parámetros del sistema
SELECT MAX(CASE WHEN cod_parametro = 'SMLMV' THEN valor_numerico END),
       MAX(CASE WHEN cod_parametro = 'AUX_TRANSPORTE'THEN valor_numerico END),
       MAX(CASE WHEN cod_parametro = 'PCT_SALUD' THEN valor_numerico END),
       MAX(CASE WHEN cod_parametro = 'PCT_PENSION' THEN valor_numerico END),
       MAX(CASE WHEN cod_parametro = 'PCT_FONDO_SOLIDARIDAD'THEN valor_numerico END),
       MAX(CASE WHEN cod_parametro = 'UMBRAL_FONDO_SMLMV' THEN valor_numerico END),
       MAX(CASE WHEN cod_parametro = 'APORTE_VOL_BOG' THEN valor_numerico END),
       MAX(CASE WHEN cod_parametro = 'BONO_CLIMA_SMA' THEN valor_numerico END)
       
      INTO vn_smlmv, vn_aux_mens, vn_pct_salud, vn_pct_pension,
           vn_pct_fondo, vn_umbral, vn_aporte_bog, vn_bono_sma
      FROM PARAMETROS;
      
-- Cálculo de devengados
    vn_base_q   := fn_salario_base_q(param_id_empleado, param_id_quincena);
    vn_recargos := fn_recargos      (param_id_empleado, param_id_quincena);
    vn_bonif    := fn_bonificacion  (param_id_empleado, param_id_quincena);

-- Auxilio de transporte
    IF vv_tipo != 'SERVICIOS' THEN
        IF vv_tipo = 'PLANTA' THEN
            vn_sal_mens := vn_salario;
        ELSE
            SELECT NVL(SUM(cantidad_horas), 0)
              INTO vn_horas_norm
              FROM HORAS_TRABAJADAS
             WHERE id_empleado = param_id_empleado
               AND id_quincena = param_id_quincena
               AND tipo_hora   = 'NORMAL';
            vn_sal_mens := vn_salario * vn_horas_norm * 2;
        END IF;

        IF vn_sal_mens <= 2 * vn_smlmv THEN
            vn_aux_transp := vn_aux_mens / 2;
        END IF;
    END IF;

-- Bono sede Santa Marta
    IF vv_tipo != 'SERVICIOS' AND vv_sede = 'SMA' THEN
        vn_bono_sede := vn_bono_sma;
    END IF;

    vn_bruto := ROUND(vn_base_q + vn_recargos + vn_bonif + vn_aux_transp + vn_bono_sede, 2);

-- Cálculo de deducciones
    vn_salud   := ROUND(vn_bruto * vn_pct_salud   / 100, 2);
    vn_pension := ROUND(vn_bruto * vn_pct_pension  / 100, 2);

    IF (vn_bruto * 2) > (vn_umbral * vn_smlmv) THEN
        vn_fondo_sol := ROUND(vn_bruto * vn_pct_fondo / 100, 2);
    END IF;

    SELECT NVL(SUM(porcentaje), 0)
    INTO vn_pct_emb
    FROM EMBARGOS
    WHERE id_empleado = param_id_empleado
    AND estado = 'ACTIVO';

    vn_embargo := ROUND(
        (vn_bruto - vn_salud - vn_pension - vn_fondo_sol) * vn_pct_emb / 100, 2);

    SELECT NVL(SUM(cuota_mensual) / 2, 0)
    INTO vn_libranzas
    FROM LIBRANZAS
    WHERE id_empleado = param_id_empleado
    AND estado = 'ACTIVA';

    IF vv_sede = 'BOG' AND vv_acepta_vol = 'S' THEN
        vn_aporte_vol := vn_aporte_bog;
    END IF;

    vn_total_ded := vn_salud + vn_pension + vn_fondo_sol + vn_embargo + vn_libranzas + vn_aporte_vol;
    vn_neto := vn_bruto - vn_total_ded;

-- Ajuste por neto negativo: retirar embargo y luego libranzas
    IF vn_neto < 0 THEN
        vn_total_ded := vn_total_ded - vn_embargo;
        vn_embargo := 0;
        vn_neto := vn_bruto - vn_total_ded;

        IF vn_neto < 0 THEN
            vn_total_ded := vn_total_ded - vn_libranzas;
            vn_libranzas := 0;
            vn_neto := vn_bruto - vn_total_ded;
        END IF;

INSERT INTO LOG_NOMINA (id_log, operacion, detalle, empleados_error)
VALUES (
    SEQ_LOG.NEXTVAL,
    'ALERTA_NETO_NEGATIVO',
        'Empleado ' || param_id_empleado|| ' quincena ' 
        || param_id_quincena|| ' — neto ajustado: ' || vn_neto, 1
    );
END IF;

INSERT INTO LIQUIDACION ( id_liquidacion,id_empleado,id_quincena,salario_base_q,recargos,
bonificacion, auxilio_transp,bono_sede,bruto,deduccion_salud,deduccion_pension,fondo_solidaridad,
embargo,libranzas,aporte_voluntario,total_deducciones, neto

) VALUES (
SEQ_LIQUIDACION.NEXTVAL, param_id_empleado, param_id_quincena,
vn_base_q,vn_recargos, vn_bonif,
vn_aux_transp,vn_bono_sede, vn_bruto,
vn_salud,vn_pension, vn_fondo_sol,
vn_embargo,vn_libranzas, vn_aporte_vol,
vn_total_ded,vn_neto
    );

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;

END sp_liquidar_empleado;
/

-- Prueba de error esperado
BEGIN
    sp_liquidar_empleado(9999, '2026-Q1-ENE');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('TEST-1 OK: ' || SQLERRM);
END;
/


-- 4.1  Especificación del paquete

CREATE OR REPLACE TYPE t_concepto_liq_obj FORCE AS OBJECT (
id_empleado       NUMBER,
id_quincena       VARCHAR2(20),
salario_base_q    NUMBER,
recargos          NUMBER,
bonificacion      NUMBER,
auxilio_transp    NUMBER,
bono_sede         NUMBER,
bruto             NUMBER,
deduccion_salud   NUMBER,
deduccion_pension NUMBER,
fondo_solidaridad NUMBER,
embargo           NUMBER,
libranzas         NUMBER,
aporte_voluntario NUMBER,
total_deducciones NUMBER,
neto              NUMBER
);
/

CREATE OR REPLACE TYPE t_lista_liq_tab FORCE AS TABLE OF t_concepto_liq_obj;
/


CREATE OR REPLACE PACKAGE pck_nomina IS

 gc_smlmv NUMBER;

TYPE t_concepto_liq IS RECORD (
id_empleado LIQUIDACION.id_empleado%TYPE,
id_quincena  LIQUIDACION.id_quincena%TYPE,
salario_base_q LIQUIDACION.salario_base_q%TYPE,
recargos  LIQUIDACION.recargos%TYPE,
bonificacion LIQUIDACION.bonificacion%TYPE,
auxilio_transp LIQUIDACION.auxilio_transp%TYPE,
bono_sede LIQUIDACION.bono_sede%TYPE,
bruto LIQUIDACION.bruto%TYPE,
deduccion_salud   LIQUIDACION.deduccion_salud%TYPE,
deduccion_pension LIQUIDACION.deduccion_pension%TYPE,
fondo_solidaridad LIQUIDACION.fondo_solidaridad%TYPE,
embargo LIQUIDACION.embargo%TYPE,
libranzas LIQUIDACION.libranzas%TYPE,
aporte_voluntario LIQUIDACION.aporte_voluntario%TYPE,
total_deducciones LIQUIDACION.total_deducciones%TYPE,
neto  LIQUIDACION.neto%TYPE

);

TYPE t_lista_liq IS TABLE OF t_concepto_liq INDEX BY PLS_INTEGER;

PROCEDURE sp_liquidar_quincena(
    param_id_empleado NUMBER,
    param_id_quincena VARCHAR2
);

PROCEDURE sp_liquidar_quincena(
    param_id_quincena VARCHAR2
);

FUNCTION fn_total_nomina_sede(
    param_cod_sede    VARCHAR2,
    param_id_quincena VARCHAR2
 ) RETURN NUMBER;

FUNCTION fn_reporte_nomina(
    param_cod_sede      VARCHAR2 DEFAULT NULL,
    param_tipo_contrato VARCHAR2 DEFAULT NULL
) RETURN t_lista_liq_tab PIPELINED;

END pck_nomina;
/


-- PUNTO 4.2: Body

CREATE OR REPLACE PACKAGE BODY pck_nomina IS

    -- Variables globales privadas
vg_smlmv        NUMBER;
vg_aux_transp   NUMBER;
vg_pct_salud    NUMBER;
vg_pct_pension  NUMBER;
vg_pct_fondo    NUMBER;
vg_umbral_fondo NUMBER;
vg_aporte_bog   NUMBER;
vg_bono_sma     NUMBER;
vg_ret_serv     NUMBER;
vg_rec_noct     NUMBER;
vg_rec_dom      NUMBER;
vg_rec_nd       NUMBER;

-- sp_log_nomina - Punto 8 
    PROCEDURE sp_log_nomina(
        param_operacion VARCHAR2,
        param_detalle   VARCHAR2,
        param_ok        NUMBER DEFAULT 0,
        param_error     NUMBER DEFAULT 0,
        param_monto     NUMBER DEFAULT 0
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO LOG_NOMINA (
            id_log, fecha_hora, operacion, usuario,
            detalle, empleados_ok, empleados_error, monto_total
        ) VALUES (
            SEQ_LOG.NEXTVAL, SYSTIMESTAMP, param_operacion, USER,
            param_detalle, param_ok, param_error, param_monto
        );
        COMMIT;
    END sp_log_nomina;


-- fn_salario_base_q
    FUNCTION fn_salario_base_q(
        param_id_empleado NUMBER,
        param_id_quincena VARCHAR2
    ) RETURN NUMBER IS
        vv_tipo    EMPLEADOS.tipo_contrato%TYPE;
        vn_salario EMPLEADOS.salario_base%TYPE;
        vn_horas   NUMBER := 0;
    BEGIN
        SELECT tipo_contrato, salario_base
          INTO vv_tipo, vn_salario
          FROM EMPLEADOS
         WHERE id_empleado = param_id_empleado;

        IF vv_tipo = 'PLANTA' THEN
            RETURN vn_salario / 2;

        ELSIF vv_tipo = 'TEMPORAL' THEN
            SELECT NVL(SUM(cantidad_horas), 0)
              INTO vn_horas
              FROM HORAS_TRABAJADAS
             WHERE id_empleado = param_id_empleado
               AND id_quincena = param_id_quincena
               AND tipo_hora   = 'NORMAL';
            RETURN vn_salario * vn_horas;

        ELSE
            RETURN vn_salario * (100 - vg_ret_serv) / 200;
        END IF;
    END fn_salario_base_q;

-- fn_recargos
    FUNCTION fn_recargos(
        param_id_empleado NUMBER,
        param_id_quincena VARCHAR2
    ) RETURN NUMBER IS
        vv_tipo       EMPLEADOS.tipo_contrato%TYPE;
        vn_salario    EMPLEADOS.salario_base%TYPE;
        vn_valor_hora NUMBER;
        vn_total      NUMBER := 0;
    BEGIN
        SELECT tipo_contrato, salario_base
          INTO vv_tipo, vn_salario
          FROM EMPLEADOS
         WHERE id_empleado = param_id_empleado;

        IF vv_tipo = 'SERVICIOS' THEN
            RETURN 0;
        END IF;

        vn_valor_hora := CASE vv_tipo
                            WHEN 'PLANTA' THEN vn_salario / 240
                            ELSE vn_salario
                         END;

        FOR vv_hora IN (
            SELECT tipo_hora, cantidad_horas
              FROM HORAS_TRABAJADAS
             WHERE id_empleado = param_id_empleado
               AND id_quincena = param_id_quincena
               AND tipo_hora IN ('NOCTURNA', 'DOMINICAL', 'NOCTURNA_DOM')
        ) LOOP
            vn_total := vn_total + vv_hora.cantidad_horas * vn_valor_hora
                        * CASE vv_hora.tipo_hora
                            WHEN 'NOCTURNA'     THEN vg_rec_noct
                            WHEN 'DOMINICAL'    THEN vg_rec_dom
                            WHEN 'NOCTURNA_DOM' THEN vg_rec_nd
                          END / 100;
        END LOOP;

        RETURN NVL(vn_total, 0);
    END fn_recargos;



-- fn_bonificacion

    FUNCTION fn_bonificacion(
        param_id_empleado NUMBER,
        param_id_quincena VARCHAR2
    ) RETURN NUMBER IS
        vv_tipo       EMPLEADOS.tipo_contrato%TYPE;
        vd_ingreso    EMPLEADOS.fecha_ingreso%TYPE;
        vn_sanciones  NUMBER;
        vn_antiguedad NUMBER;
        vn_pct        NUMBER := 0;
    BEGIN
        SELECT tipo_contrato, fecha_ingreso
          INTO vv_tipo, vd_ingreso
          FROM EMPLEADOS
         WHERE id_empleado = param_id_empleado;

        IF vv_tipo = 'SERVICIOS' THEN
            RETURN 0;
        END IF;

        SELECT COUNT(*)
          INTO vn_sanciones
          FROM SANCIONES
         WHERE id_empleado   = param_id_empleado
           AND fecha_sancion >= ADD_MONTHS(SYSDATE, -6);

        IF vn_sanciones > 2 THEN
            RETURN 0;
        END IF;

        vn_antiguedad := TRUNC(MONTHS_BETWEEN(SYSDATE, vd_ingreso) / 12);

        IF    vn_antiguedad BETWEEN 3 AND 5  THEN vn_pct := 3;
        ELSIF vn_antiguedad BETWEEN 6 AND 10 THEN vn_pct := 6;
        ELSIF vn_antiguedad > 10             THEN vn_pct := 10;
        END IF;

        RETURN ROUND(fn_salario_base_q(param_id_empleado, param_id_quincena) * vn_pct / 100, 2);
    END fn_bonificacion;



-- calcular_liq: Arma el registro completo de un empleado

    FUNCTION calcular_liq(
        param_id_empleado NUMBER,
        param_id_quincena VARCHAR2
    ) RETURN t_concepto_liq IS

        vv_liq      t_concepto_liq;
        vv_tipo     EMPLEADOS.tipo_contrato%TYPE;
        vv_sede     EMPLEADOS.cod_sede%TYPE;
        vn_salario  EMPLEADOS.salario_base%TYPE;
        vn_horas    NUMBER := 0;
        vn_sal_mes  NUMBER;
        vn_bruto    NUMBER;
        vn_salud    NUMBER;
        vn_pension  NUMBER;
        vn_fondo    NUMBER;
        vn_embargo  NUMBER;
        vn_libranza NUMBER;
        vn_aporte   NUMBER;
        vn_pct_emb  NUMBER := 0;

    BEGIN
        SELECT tipo_contrato, cod_sede, salario_base
          INTO vv_tipo, vv_sede, vn_salario
          FROM EMPLEADOS
         WHERE id_empleado = param_id_empleado;

        vv_liq.id_empleado    := param_id_empleado;
        vv_liq.id_quincena    := param_id_quincena;
        vv_liq.salario_base_q := fn_salario_base_q(param_id_empleado, param_id_quincena);
        vv_liq.recargos       := fn_recargos       (param_id_empleado, param_id_quincena);
        vv_liq.bonificacion   := fn_bonificacion   (param_id_empleado, param_id_quincena);

        -- Auxilio de transporte
        vv_liq.auxilio_transp := 0;
        IF vv_tipo != 'SERVICIOS' THEN
            IF vv_tipo = 'PLANTA' THEN
                vn_sal_mes := vn_salario;
            ELSE
                SELECT NVL(SUM(cantidad_horas), 0)
                  INTO vn_horas
                  FROM HORAS_TRABAJADAS
                 WHERE id_empleado = param_id_empleado
                   AND id_quincena = param_id_quincena
                   AND tipo_hora   = 'NORMAL';
                vn_sal_mes := vn_salario * vn_horas * 2;
            END IF;

            IF vn_sal_mes <= 2 * vg_smlmv THEN
                vv_liq.auxilio_transp := vg_aux_transp / 2;
            END IF;
        END IF;

        -- Bono sede Santa Marta
        vv_liq.bono_sede := 0;
        IF vv_sede = 'SMA' AND vv_tipo != 'SERVICIOS' THEN
            vv_liq.bono_sede := vg_bono_sma;
        END IF;

        -- Bruto
        vn_bruto     := ROUND(vv_liq.salario_base_q + vv_liq.recargos + vv_liq.bonificacion
                            + vv_liq.auxilio_transp  + vv_liq.bono_sede, 2);
        vv_liq.bruto := vn_bruto;

        -- Deducciones
        vn_salud   := ROUND(vn_bruto * vg_pct_salud  / 100, 2);
        vn_pension := ROUND(vn_bruto * vg_pct_pension / 100, 2);
        vn_fondo   := 0;

        IF (vn_bruto * 2) > (vg_umbral_fondo * vg_smlmv) THEN
            vn_fondo := ROUND(vn_bruto * vg_pct_fondo / 100, 2);
        END IF;

        SELECT NVL(SUM(porcentaje), 0)
          INTO vn_pct_emb
          FROM EMBARGOS
         WHERE id_empleado = param_id_empleado
           AND estado = 'ACTIVO';

        vn_embargo := ROUND(
            (vn_bruto - vn_salud - vn_pension - vn_fondo) * vn_pct_emb / 100, 2);

        SELECT NVL(SUM(cuota_mensual) / 2, 0)
          INTO vn_libranza
          FROM LIBRANZAS
         WHERE id_empleado = param_id_empleado
           AND estado      = 'ACTIVA';

        vn_aporte := 0;
        IF vv_sede = 'BOG' THEN
            SELECT CASE WHEN acepta_aporte_vol = 'S' THEN vg_aporte_bog ELSE 0 END
              INTO vn_aporte
              FROM EMPLEADOS
             WHERE id_empleado = param_id_empleado;
        END IF;

        vv_liq.deduccion_salud   := vn_salud;
        vv_liq.deduccion_pension := vn_pension;
        vv_liq.fondo_solidaridad := vn_fondo;
        vv_liq.embargo           := vn_embargo;
        vv_liq.libranzas         := vn_libranza;
        vv_liq.aporte_voluntario := vn_aporte;
        vv_liq.total_deducciones := vn_salud + vn_pension + vn_fondo
                                    + vn_embargo + vn_libranza + vn_aporte;
        vv_liq.neto              := vn_bruto - vv_liq.total_deducciones;

        -- Ajuste por neto negativo
        IF vv_liq.neto < 0 THEN
            vv_liq.total_deducciones := vv_liq.total_deducciones - vv_liq.embargo;
            vv_liq.embargo           := 0;
            vv_liq.neto              := vn_bruto - vv_liq.total_deducciones;

            IF vv_liq.neto < 0 THEN
                vv_liq.total_deducciones := vv_liq.total_deducciones - vv_liq.libranzas;
                vv_liq.libranzas         := 0;
                vv_liq.neto              := vn_bruto - vv_liq.total_deducciones;
            END IF;

            IF vv_liq.neto < 0 THEN
                sp_log_nomina('ALERTA_NETO_NEGATIVO',
                    'Empleado ' || param_id_empleado || ' neto=' || vv_liq.neto, 0, 1, 0);
            END IF;
        END IF;

        RETURN vv_liq;
    END calcular_liq;



-- sp_liquidar_quincena (individual)

    PROCEDURE sp_liquidar_quincena(
        param_id_empleado NUMBER,
        param_id_quincena VARCHAR2
    ) IS
        vv_estado EMPLEADOS.estado%TYPE;
        vn_existe NUMBER;
        vv_liq    t_concepto_liq;
    BEGIN
        BEGIN
            SELECT estado
              INTO vv_estado
              FROM EMPLEADOS
             WHERE id_empleado = param_id_empleado;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20001,
                    'Empleado no encontrado: ' || param_id_empleado);
        END;

        IF vv_estado != 'ACTIVO' THEN
            RAISE_APPLICATION_ERROR(-20002, 'El empleado no está activo.');
        END IF;

        SELECT COUNT(*)
          INTO vn_existe
          FROM LIQUIDACION
         WHERE id_empleado = param_id_empleado
           AND id_quincena = param_id_quincena;

        IF vn_existe > 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Ya existe liquidación para esa quincena.');
        END IF;

        vv_liq := calcular_liq(param_id_empleado, param_id_quincena);

        INSERT INTO LIQUIDACION VALUES (
            SEQ_LIQUIDACION.NEXTVAL,
            vv_liq.id_empleado,       vv_liq.id_quincena,
            vv_liq.salario_base_q,    vv_liq.recargos,          vv_liq.bonificacion,
            vv_liq.auxilio_transp,    vv_liq.bono_sede,          vv_liq.bruto,
            vv_liq.deduccion_salud,   vv_liq.deduccion_pension,  vv_liq.fondo_solidaridad,
            vv_liq.embargo,           vv_liq.libranzas,          vv_liq.aporte_voluntario,
            vv_liq.total_deducciones, vv_liq.neto,               SYSDATE
        );

        sp_log_nomina('LIQUIDACION_INDIVIDUAL',
            'Empleado ' || param_id_empleado || ' neto=' || vv_liq.neto,
            1, 0, vv_liq.neto);

        COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            sp_log_nomina('ERROR_LIQUIDACION',
                'Empleado ' || param_id_empleado || ': ' || SQLERRM, 0, 1, 0);
            RAISE;
    END sp_liquidar_quincena;



-- sp_liquidar_quincena -- Punto 6 

    PROCEDURE sp_liquidar_quincena(param_id_quincena VARCHAR2) IS

        TYPE t_ids IS TABLE OF EMPLEADOS.id_empleado%TYPE;
        vt_ids        t_ids;
        vt_liqs       t_lista_liq;
        e_bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_bulk_errors, -24381);

        vn_ok    NUMBER := 0;
        vn_error NUMBER := 0;
        vn_total NUMBER := 0;
        vn_idx   PLS_INTEGER;

    BEGIN
        SELECT id_empleado
          BULK COLLECT INTO vt_ids
          FROM EMPLEADOS
         WHERE estado = 'ACTIVO'
           AND id_empleado NOT IN (
               SELECT id_empleado
                 FROM LIQUIDACION
                WHERE id_quincena = param_id_quincena);

        IF vt_ids.COUNT = 0 THEN
            DBMS_OUTPUT.PUT_LINE(
                'No hay empleados pendientes para la quincena ' || param_id_quincena);
            RETURN;
        END IF;

        FOR i IN 1 .. vt_ids.COUNT LOOP
            BEGIN
                vt_liqs(i) := calcular_liq(vt_ids(i), param_id_quincena);
                vn_total   := vn_total + NVL(vt_liqs(i).neto, 0);
            EXCEPTION
                WHEN OTHERS THEN
                    vn_error := vn_error + 1;
                    sp_log_nomina('ERROR_CALCULO',
                        'Empleado ' || vt_ids(i) || ': ' || SQLERRM, 0, 1, 0);
                    vt_liqs.DELETE(i);
            END;
        END LOOP;

        BEGIN
            FORALL i IN INDICES OF vt_liqs SAVE EXCEPTIONS
                INSERT INTO LIQUIDACION VALUES (
                    SEQ_LIQUIDACION.NEXTVAL,
                    vt_liqs(i).id_empleado,       vt_liqs(i).id_quincena,
                    vt_liqs(i).salario_base_q,    vt_liqs(i).recargos,
                    vt_liqs(i).bonificacion,       vt_liqs(i).auxilio_transp,
                    vt_liqs(i).bono_sede,          vt_liqs(i).bruto,
                    vt_liqs(i).deduccion_salud,    vt_liqs(i).deduccion_pension,
                    vt_liqs(i).fondo_solidaridad,  vt_liqs(i).embargo,
                    vt_liqs(i).libranzas,          vt_liqs(i).aporte_voluntario,
                    vt_liqs(i).total_deducciones,  vt_liqs(i).neto,
                    SYSDATE
                );
            vn_ok := SQL%ROWCOUNT;

        EXCEPTION
            WHEN e_bulk_errors THEN
                FOR j IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                    vn_error := vn_error + 1;
                    vn_idx   := SQL%BULK_EXCEPTIONS(j).ERROR_INDEX;
                    sp_log_nomina('ERROR_INSERT',
                        'Empleado ' || vt_liqs(vn_idx).id_empleado
                        || ' — ' || SQLERRM(-SQL%BULK_EXCEPTIONS(j).ERROR_CODE),
                        0, 1, 0);
                END LOOP;
                vn_ok := vt_liqs.COUNT - vn_error;
        END;

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Procesados OK: ' || vn_ok || ' | Errores: ' || vn_error);
        sp_log_nomina('LIQUIDACION_MASIVA',
            'Quincena ' || param_id_quincena, vn_ok, vn_error, vn_total);

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            sp_log_nomina('ERROR_MASIVO', SQLERRM, 0, 0, 0);
            RAISE;
    END sp_liquidar_quincena;


-- fn_total_nomina_sede

    FUNCTION fn_total_nomina_sede(
        param_cod_sede    VARCHAR2,
        param_id_quincena VARCHAR2
    ) RETURN NUMBER IS
        vn_total NUMBER;
    BEGIN
        SELECT NVL(SUM(l.neto), 0)
          INTO vn_total
          FROM LIQUIDACION l
          JOIN EMPLEADOS e ON e.id_empleado = l.id_empleado
         WHERE e.cod_sede    = param_cod_sede
           AND l.id_quincena = param_id_quincena;
        RETURN vn_total;
    END fn_total_nomina_sede;

-- fn_reporte_nomina -- Punto 7 

    FUNCTION fn_reporte_nomina(
        param_cod_sede      VARCHAR2 DEFAULT NULL,
        param_tipo_contrato VARCHAR2 DEFAULT NULL
    ) RETURN t_lista_liq_tab PIPELINED IS

        TYPE t_refcursor IS REF CURSOR;
        vv_cur t_refcursor;
        vv_sql VARCHAR2(2000);
        vv_row t_concepto_liq_obj := t_concepto_liq_obj(
            NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
            NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
        );

    BEGIN
        vv_sql :=
            'SELECT l.id_empleado, l.id_quincena,
                    l.salario_base_q, l.recargos, l.bonificacion,
                    l.auxilio_transp, l.bono_sede, l.bruto,
                    l.deduccion_salud, l.deduccion_pension, l.fondo_solidaridad,
                    l.embargo, l.libranzas, l.aporte_voluntario,
                    l.total_deducciones, l.neto
               FROM LIQUIDACION l
               JOIN EMPLEADOS e ON e.id_empleado = l.id_empleado
              WHERE 1=1';

        IF param_cod_sede IS NOT NULL THEN
            vv_sql := vv_sql || ' AND e.cod_sede = :1';
        END IF;
        IF param_tipo_contrato IS NOT NULL THEN
            vv_sql := vv_sql || ' AND e.tipo_contrato = :2';
        END IF;

        IF    param_cod_sede IS NOT NULL AND param_tipo_contrato IS NOT NULL THEN
            OPEN vv_cur FOR vv_sql USING param_cod_sede, param_tipo_contrato;
        ELSIF param_cod_sede IS NOT NULL THEN
            OPEN vv_cur FOR vv_sql USING param_cod_sede;
        ELSIF param_tipo_contrato IS NOT NULL THEN
            OPEN vv_cur FOR vv_sql USING param_tipo_contrato;
        ELSE
            OPEN vv_cur FOR vv_sql;
        END IF;

        LOOP
            FETCH vv_cur INTO
                vv_row.id_empleado,        vv_row.id_quincena,
                vv_row.salario_base_q,     vv_row.recargos,          vv_row.bonificacion,
                vv_row.auxilio_transp,     vv_row.bono_sede,          vv_row.bruto,
                vv_row.deduccion_salud,    vv_row.deduccion_pension,  vv_row.fondo_solidaridad,
                vv_row.embargo,            vv_row.libranzas,          vv_row.aporte_voluntario,
                vv_row.total_deducciones,  vv_row.neto;
            EXIT WHEN vv_cur%NOTFOUND;
            PIPE ROW(vv_row);
        END LOOP;

        CLOSE vv_cur;
    END fn_reporte_nomina;

-- Bloque de inicialización: carga parámetros al arrancar
BEGIN
    SELECT MAX(CASE WHEN cod_parametro = 'SMLMV'                THEN valor_numerico END),
           MAX(CASE WHEN cod_parametro = 'AUX_TRANSPORTE'        THEN valor_numerico END),
           MAX(CASE WHEN cod_parametro = 'PCT_SALUD'             THEN valor_numerico END),
           MAX(CASE WHEN cod_parametro = 'PCT_PENSION'           THEN valor_numerico END),
           MAX(CASE WHEN cod_parametro = 'PCT_FONDO_SOLIDARIDAD' THEN valor_numerico END),
           MAX(CASE WHEN cod_parametro = 'UMBRAL_FONDO_SMLMV'   THEN valor_numerico END),
           MAX(CASE WHEN cod_parametro = 'APORTE_VOL_BOG'        THEN valor_numerico END),
           MAX(CASE WHEN cod_parametro = 'BONO_CLIMA_SMA'        THEN valor_numerico END),
           MAX(CASE WHEN cod_parametro = 'RET_SERVICIOS'         THEN valor_numerico END),
           MAX(CASE WHEN cod_parametro = 'RECARGO_NOCTURNO'      THEN valor_numerico END),
           MAX(CASE WHEN cod_parametro = 'RECARGO_DOMINICAL'     THEN valor_numerico END),
           MAX(CASE WHEN cod_parametro = 'RECARGO_NOCT_DOM'      THEN valor_numerico END)
      INTO vg_smlmv,      vg_aux_transp,   vg_pct_salud,  vg_pct_pension,
           vg_pct_fondo,  vg_umbral_fondo, vg_aporte_bog, vg_bono_sma,
           vg_ret_serv,   vg_rec_noct,     vg_rec_dom,    vg_rec_nd
      FROM PARAMETROS;

    gc_smlmv := vg_smlmv;

END pck_nomina;
/



-- PUNTO 5: Trigger 

CREATE OR REPLACE PROCEDURE sp_log_trigger(
    param_operacion VARCHAR2,
    param_detalle   VARCHAR2,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
    param_ok        NUMBER DEFAULT 0,
    param_error     NUMBER DEFAULT 0
) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO LOG_NOMINA (id_log, operacion, detalle, empleados_ok, empleados_error)
    VALUES (SEQ_LOG.NEXTVAL, param_operacion, param_detalle, param_ok, param_error);
    COMMIT;
END sp_log_trigger;
/

CREATE OR REPLACE TRIGGER TGR_LIQ_COMPOUND
FOR INSERT ON LIQUIDACION
COMPOUND TRIGGER

TYPE tr_ajuste IS RECORD (
    vn_id_empleado  NUMBER,
    vv_ajustado     VARCHAR2(1),
    vn_neto_orig    NUMBER,
    vn_neto_final   NUMBER
);
TYPE tt_ajustes IS TABLE OF tr_ajuste INDEX BY PLS_INTEGER;

vt_ajustes tt_ajustes;
vn_indice  PLS_INTEGER := 0;

BEFORE EACH ROW IS
    vn_neto_original NUMBER;
    vb_ajustado      BOOLEAN := FALSE;
BEGIN
    IF :NEW.salario_base_q < 0 THEN
        RAISE_APPLICATION_ERROR(-20010,
            'Salario base no puede ser negativo para empleado ' || :NEW.id_empleado);
    END IF;

    vn_neto_original := :NEW.neto;

    IF :NEW.neto < 0 THEN
        :NEW.total_deducciones := :NEW.total_deducciones - :NEW.embargo;
        :NEW.embargo := 0;
        :NEW.neto    := :NEW.bruto - :NEW.total_deducciones;
        vb_ajustado  := TRUE;

        IF :NEW.neto < 0 THEN
            :NEW.total_deducciones := :NEW.total_deducciones - :NEW.libranzas;
            :NEW.libranzas         := 0;
            :NEW.neto              := :NEW.bruto - :NEW.total_deducciones;
        END IF;
    END IF;

    vn_indice := vn_indice + 1;
    vt_ajustes(vn_indice).vn_id_empleado := :NEW.id_empleado;
    vt_ajustes(vn_indice).vv_ajustado    := CASE WHEN vb_ajustado THEN 'S' ELSE 'N' END;
    vt_ajustes(vn_indice).vn_neto_orig   := vn_neto_original;
    vt_ajustes(vn_indice).vn_neto_final  := :NEW.neto;

END BEFORE EACH ROW;

AFTER EACH ROW IS
BEGIN
    IF vt_ajustes(vn_indice).vv_ajustado = 'S' THEN
        sp_log_trigger(
            'ALERTA_NETO_NEGATIVO',
            'Empleado '      || :NEW.id_empleado
            || ' — Neto original: '
            || TO_CHAR(vt_ajustes(vn_indice).vn_neto_orig,  '999,999,990.00')
            || ' | Neto ajustado: '
            || TO_CHAR(vt_ajustes(vn_indice).vn_neto_final, '999,999,990.00'),
            0, 1
        );
    END IF;
END AFTER EACH ROW;

AFTER STATEMENT IS
    vn_total_registros NUMBER;
    vn_total_ajustados NUMBER := 0;
BEGIN
    vn_total_registros := vt_ajustes.COUNT;

    FOR i IN 1 .. vt_ajustes.COUNT LOOP
        IF vt_ajustes(i).vv_ajustado = 'S' THEN
            vn_total_ajustados := vn_total_ajustados + 1;
        END IF;
    END LOOP;

    sp_log_trigger(
        'INSERT_LIQUIDACION',
        'Lote procesado a las '
        || TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF3')
        || ' | Total registros: '              || vn_total_registros
        || ' | Ajustados por neto negativo: '  || vn_total_ajustados,
        vn_total_registros - vn_total_ajustados,
        vn_total_ajustados
    );

    vt_ajustes.DELETE;
    vn_indice := 0;

END AFTER STATEMENT;

END TGR_LIQ_COMPOUND;
/


-- Liquidar todos los empleados de la quincena
BEGIN
    pck_nomina.sp_liquidar_quincena('2026-Q1-ENE');
END;
/

--resultados
SELECT id_empleado, bruto, total_deducciones, neto
FROM LIQUIDACION
ORDER BY id_empleado;



