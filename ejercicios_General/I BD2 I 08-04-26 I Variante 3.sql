SET SERVEROUTPUT ON
SET FEEDBACK ON

-- ============================================================
-- 0. ENCABEZADO OBLIGATORIO
-- Complete toda esta información antes de ejecutar el script.
-- ============================================================
-- Integrante 1: Samuel Steven Calero Sanchez
-- Integrante 2: Sergio andres valderrama velez 
-- Curso: Bases de datos 2
-- Fecha: 8/04/2026
-- Variante asignada por el docente (1, 2, 3 o 4): 3
-- Tag de ejecución final (ejemplo: P03_FINAL): P03_FINAL

DEFINE p_variant_id = 3
DEFINE p_execution_tag = P03_FINAL

PROMPT ===== 0. VERIFICACIÓN DE LA VARIANTE ASIGNADA =====
SELECT
    variant_id,
    variant_name,
    excluded_department_id,
    min_years_service,
    recent_job_history_months,
    gap_high_threshold_pct,
    gap_mid_threshold_pct,
    raise_high_pct,
    raise_mid_pct,
    raise_low_pct,
    max_salary_vs_avg_pct,
    notes
FROM
    t1_variants
WHERE
    variant_id = &p_variant_id;



-- ============================================================
-- GUÍA RÁPIDA DE OBJETOS DISPONIBLES
-- Use estos nombres reales de tablas y columnas.
-- ============================================================
-- Tabla principal de empleados: T1_EMPLOYEES
-- Columnas más importantes:
--   employee_id, first_name, last_name, email, phone_number,
--   hire_date, job_id, salary, commission_pct, manager_id, department_id
--
-- Tabla de departamentos: T1_DEPARTMENTS
-- Columnas más importantes:
--   department_id, department_name, manager_id, location_id
--
-- Tabla de historial laboral: T1_JOB_HISTORY
-- Columnas más importantes:
--   employee_id, start_date, end_date, job_id, department_id
--
-- Tabla de auditoría: AUDIT_SALARY_ADJUSTMENTS_T1
-- Columnas:
--   audit_id, execution_tag, variant_id, employee_id, department_id,
--   salary_before, salary_after, pct_gap_to_avg_before, rule_applied,
--   executed_by, executed_at, notes
--
-- Tabla de variantes: T1_VARIANTS
-- Columnas:
--   variant_id, variant_name, excluded_department_id, min_years_service,
--   recent_job_history_months, gap_high_threshold_pct,
--   gap_mid_threshold_pct, raise_high_pct, raise_mid_pct,
--   raise_low_pct, max_salary_vs_avg_pct, notes

-- ============================================================
-- GUÍA RÁPIDA DE TÉRMINOS QUE DEBE USAR EN SU SOLUCIÓN
-- ============================================================
-- CTE:
--   Una CTE es una consulta temporal escrita con WITH.
--   Sirve para dividir una consulta grande en partes más claras.
--
--   Ejemplo:
--   WITH dept_stats AS (
--       SELECT department_id, AVG(salary) avg_salary
--       FROM t1_employees
--       GROUP BY department_id
--   )
--   SELECT *
--   FROM dept_stats;
--
-- Función analítica:
--   Es una función como ROW_NUMBER, RANK o DENSE_RANK.
--   Sirve para calcular posiciones o comparaciones sin perder el detalle.
--
--   Ejemplo:
--   DENSE_RANK() OVER (PARTITION BY department_id ORDER BY salary DESC)
--
-- JOIN:
--   Es la unión entre tablas relacionadas, por ejemplo empleados y departamentos.
--
-- Subconsulta:
--   Es una consulta dentro de otra consulta.
--
-- SAVEPOINT:
--   Es un punto de restauración dentro de una transacción.
--   Permite devolver la operación a un punto intermedio con ROLLBACK TO.

-- Analisis 



-- ============================================================
-- 1. CONSULTA DIAGNÓSTICA
-- OBJETIVO:
-- Analizar la información antes de actualizar salarios.
--
-- SU CONSULTA DEBE MOSTRAR, COMO MÍNIMO, ESTAS COLUMNAS:
--   employee_id
--   first_name
--   last_name
--   job_id
--   manager_id
--   department_id
--   department_name
--   salary
--   hire_date
--   years_service
--   dept_avg_salary
--   dept_max_salary
--   dept_employee_count
--   pct_gap_to_avg
--   recent_job_history_flag
--   salary_rank_in_department
--
-- QUÉ SIGNIFICA CADA COLUMNA:
--   years_service: años de antigüedad del empleado
--   dept_avg_salary: promedio salarial del departamento
--   dept_max_salary: salario más alto del departamento
--   dept_employee_count: cantidad de empleados del departamento
--   pct_gap_to_avg: porcentaje que le falta al salario del empleado para llegar
--                   al promedio del departamento
--   recent_job_history_flag: SI o NO, según si tuvo historial reciente
--   salary_rank_in_department: posición salarial dentro del departamento
--
-- IMPORTANTE:
-- - Puede usar una o varias CTE
-- - Debe usar al menos una función analítica
-- - Debe unir como mínimo T1_EMPLOYEES con T1_DEPARTMENTS
-- - Debe revisar T1_JOB_HISTORY para detectar historial reciente
-- ============================================================

PROMPT ===== 1. CONSULTA DIAGNÓSTICA =====

-- ESCRIBA AQUÍ SU CONSULTA DIAGNÓSTICA PRINCIPAL


WITH stats_depto AS (
    SELECT
        department_id,
        COUNT(*) AS total_empleados,
        AVG(salary) AS salario_promedio,
        MAX(salary) AS salario_maximo
    FROM   t1_employees
    WHERE  department_id IS NOT NULL
    GROUP BY department_id
),
-- CTE 2: ¿El empleado tuvo cambios en los últimos 24 meses?
historial_reciente AS (
    SELECT
        employee_id,
        CASE
            WHEN MAX(start_date) > ADD_MONTHS(SYSDATE, -24) THEN 'SI'
            ELSE 'NO'
        END AS cambio_reciente
    FROM   t1_job_history
    GROUP BY employee_id
)

SELECT
    -- Datos del empleado
    e.employee_id,
    e.first_name,
    e.last_name,
    e.job_id,
    e.manager_id,
    e.department_id,
    d.department_name,
    e.salary,
    e.hire_date,
    
    -- Años trabajados 
    ROUND((SYSDATE - e.hire_date) / 365, 1) AS anios_antiguedad,

    -- Indicadores del departamento 
    ROUND(NVL(sd.salario_promedio, 0), 2) AS salario_promedio_depto,
    ROUND(NVL(sd.salario_maximo,   0), 2) AS salario_maximo_depto,
    NVL(sd.total_empleados, 0) AS total_empleados_depto,

    -- % de diferencia respecto al promedio del depto
    ROUND(NVL((e.salary - sd.salario_promedio) /
    NULLIF(sd.salario_promedio, 0) * 100, 0), 2) AS pct_vs_promedio,

    -- verifica si tuvo algún cambio laboral 
    NVL(hr.cambio_reciente, 'NO') AS cambio_reciente,

    -- Posición salarial 
    DENSE_RANK() OVER (
        PARTITION BY e.department_id
        ORDER BY e.salary DESC) AS ranking_salario_depto

FROM
    t1_employees  e
    LEFT JOIN t1_departments  d  ON e.department_id = d.department_id
    LEFT JOIN stats_depto sd ON e.department_id = sd.department_id
    LEFT JOIN historial_reciente hr ON e.employee_id  = hr.employee_id

WHERE  e.employee_id IS NOT NULL
ORDER BY
    e.department_id,
    e.salary DESC;

-- ¿ Que hace cada Columna? 

/**
employee_id - ID único del empleado

first_name - Nombre del empleado

last_name - Apellido del empleado

job_id - Código del puesto de trabajo

manager_id- ID del jefe. Si el empleado es manager de otros → se excluye

department_id - ID del departamento. Si es 100 → excluido

department_name- Nombre del departamento

salary - Salario actual del empleado

hire_date - Fecha de contratación

anios_antiguedad- Años trabajados. Debe ser ≥ 4 años

salario_promedio_depto - Promedio salarial del departamento

salario_maximo_depto - Salario más alto del departamento

total_empleados_depto - Cantidad de empleados en el depto. Debe ser ≥ 3

pct_vs_promedio - % de desviación vs promedio. Debe estar entre -6% y +12%

cambio_reciente- 'SI' si cambió puesto en últimos 24 meses. Debe ser 'NO'

ranking_salario_depto - Posición salarial (1 = más alto). Rank 1 suele ser manager → se excluye


/**
-- COMENTARIO OBLIGATORIO:

La consulta  demuestra la situación actual de cada empleado mostrando su antigüedad en años, la brecha salarial respecto al promedio de su departamento (pct_vs_promedio),
si tuvo cambios laborales en los últimos 24 meses (cambio_reciente), y su ranking salarial dentro del departamento. Esta información es clave para la Variante 3 porque permite 
identificar rápidamente quiénes cumplen los criterios de elegibilidad: antigüedad mayor 4 años.

*/

-- ============================================================
-- 2. DECISIÓN DE POBLACIÓN ELEGIBLE
-- OBJETIVO:
-- Determinar qué empleados sí califican, cuáles no califican y por qué.
--
-- SU CONSULTA DEBE MOSTRAR, COMO MÍNIMO, ESTAS COLUMNAS:
--   employee_id
--   first_name
--   last_name
--   department_id
--   department_name
--   salary
--   years_service
--   dept_avg_salary
--   dept_max_salary
--   dept_employee_count
--   pct_gap_to_avg
--   recent_job_history_flag
--   manager_or_exec_flag
--   eligibility_flag
--   exclusion_reason
--   adjustment_pct
--   rule_applied
--
-- QUÉ SIGNIFICA CADA COLUMNA:
--   manager_or_exec_flag: SI o NO, según si es gerente principal o alta dirección
--   eligibility_flag: ELEGIBLE o NO_ELEGIBLE
--   exclusion_reason: motivo de exclusión, por ejemplo:
--                     SIN_DEPARTAMENTO, HISTORIAL_RECIENTE,
--                     ANTIGUEDAD_INSUFICIENTE, MANAGER_O_DIRECTIVO,
--                     DEPTO_EXCLUIDO, DEPTO_MENOR_A_3, SALARIO_NO_APLICA
--   adjustment_pct: porcentaje de ajuste que le corresponde
--   rule_applied: regla aplicada, por ejemplo AJUSTE_ALTO, AJUSTE_MEDIO, AJUSTE_BAJO
--
-- IMPORTANTE:
-- - Debe tomar en cuenta la variante asignada por el docente
-- - Debe usar los valores de T1_VARIANTS según &p_variant_id
-- - Debe quedar visible por qué una persona sí o no entra al proceso


-- ============================================================

PROMPT ===== 2. DECISIÓN DE ELEGIBLES =====

-- ESCRIBA AQUÍ SU CONSULTA DE DECISIÓN DE ELEGIBLES
WITH dept_stats AS (
    SELECT department_id,
           COUNT(*) dept_count,
           AVG(salary) dept_avg,
           MAX(salary) dept_max
    FROM   t1_employees
    WHERE  department_id IS NOT NULL
    GROUP  BY department_id
),
hist AS (
    SELECT DISTINCT employee_id
    FROM   t1_job_history
    WHERE  start_date > ADD_MONTHS(SYSDATE, -24)   
),
managers AS (
    SELECT DISTINCT manager_id AS employee_id
    FROM   t1_employees
    WHERE  manager_id IS NOT NULL
),
base AS (
    SELECT e.employee_id,
           e.first_name,
           e.last_name,
           e.department_id,
           d.department_name,
           e.salary,
           ROUND((SYSDATE - e.hire_date) / 365, 1)AS years_service,
           ROUND(ds.dept_avg, 2)AS dept_avg_salary,
           ROUND(ds.dept_max, 2) AS dept_max_salary, ds.dept_count AS dept_employee_count,
           ROUND((ds.dept_avg - e.salary) / NULLIF(ds.dept_avg,0) * 100, 2) AS pct_gap_to_avg,
           CASE WHEN h.employee_id IS NOT NULL THEN 'SI' ELSE 'NO' END AS recent_job_history_flag,
           CASE WHEN m.employee_id IS NOT NULL THEN 'SI' ELSE 'NO' END AS manager_or_exec_flag
    FROM   t1_employees   e
           LEFT JOIN t1_departments d  ON e.department_id = d.department_id
           LEFT JOIN dept_stats ds ON e.department_id = ds.department_id
           LEFT JOIN hist h  ON e.employee_id   = h.employee_id
           LEFT JOIN managers m  ON e.employee_id   = m.employee_id
)
SELECT
    employee_id,
    first_name,
    last_name,
    department_id,
    department_name,
    salary,
    years_service,
    dept_avg_salary,
    dept_max_salary,
    dept_employee_count,
    pct_gap_to_avg,
    recent_job_history_flag,
    manager_or_exec_flag,
    -- ELEGIBILIDAD
    CASE
        WHEN department_id     IS NULL  THEN 'NO_ELEGIBLE'
        WHEN department_id     = 100    THEN 'NO_ELEGIBLE'  
        WHEN dept_employee_count < 3    THEN 'NO_ELEGIBLE'
        WHEN years_service       < 4    THEN 'NO_ELEGIBLE'   
        WHEN recent_job_history_flag='SI' THEN 'NO_ELEGIBLE'
        WHEN manager_or_exec_flag   ='SI' THEN 'NO_ELEGIBLE'
        ELSE 'ELEGIBLE'
    END AS eligibility_flag,
    -- MOTIVO
    CASE
        WHEN department_id     IS NULL    THEN 'SIN_DEPARTAMENTO'
        WHEN department_id     = 100      THEN 'DEPTO_EXCLUIDO'
        WHEN dept_employee_count < 3      THEN 'DEPTO_MENOR_A_3'
        WHEN years_service       < 4      THEN 'ANTIGUEDAD_INSUFICIENTE'
     
        WHEN manager_or_exec_flag   ='SI' THEN 'MANAGER_O_DIRECTIVO'
        ELSE NULL
    END AS exclusion_reason,
    CASE
        WHEN department_id IS NULL OR department_id=100
          OR dept_employee_count < 3 OR years_service < 4
          OR recent_job_history_flag='SI' OR manager_or_exec_flag='SI' THEN NULL
        WHEN pct_gap_to_avg >= 12 THEN 12   
        WHEN pct_gap_to_avg >=  6 THEN  8   
        ELSE 5                              
    END AS adjustment_pct,
    -- REGLA APLICADA
    CASE
        WHEN department_id IS NULL OR department_id=100
          OR dept_employee_count < 3 OR years_service < 4
          OR recent_job_history_flag='SI' OR manager_or_exec_flag='SI' THEN NULL
        WHEN pct_gap_to_avg >= 12 THEN 'AJUSTE_ALTO'
        WHEN pct_gap_to_avg >=  6 THEN 'AJUSTE_MEDIO'
        ELSE 'AJUSTE_BAJO'
    END AS rule_applied
FROM base
ORDER BY eligibility_flag DESC, department_id, salary DESC;

/**

employee_id	- ID único del empleado

first_name, last_name	- Nombre y apellido

department_id, department_name - ID y nombre del departamento

salary- Salario actual del empleado

years_service- Años de servicio (fecha actual - fecha contratación / 365)

dept_avg_salary	- Salario promedio del departamento

dept_max_salary	- Salario máximo del departamento

dept_employee_count - Cantidad de empleados en el departamento

pct_gap_to_avg - Porcentaje de diferencia entre el salario del empleado y el promedio del depto.

Comentario Obligatorio

se excluye el departamento 100, empleados con menosde 4 años de antigüedad, quienes tuvieron cambio laboral en los últimos 24 meses,
managers, departamentos con menos de 3 empleados y empleados sin departamento.
*/

-- ============================================================
-- 3. PREVALIDACIÓN ANTES DE LA TRANSACCIÓN
-- OBJETIVO:
-- Mostrar qué pasaría antes de ejecutar el cambio real.
--
-- DEBE MOSTRAR, COMO MÍNIMO:
-- A. Un resumen con estas columnas:

--
-- B. Un detalle de empleados elegibles con estas columnas:
--    employee_id
--    department_id
--    salary_before
--    salary_after
--    adjustment_pct
--    rule_applied
--
-- C. Un control de topes por departamento con estas columnas:
--    department_id
--    department_name
--    dept_avg_salary
--    dept_max_salary
--    max_allowed_salary_by_variant
--
-- QUÉ SIGNIFICA:
--   total_salary_before: suma de salarios antes del ajuste
--   total_salary_after: suma de salarios proyectados después del ajuste
--   total_increment: incremento total proyectado
--   max_allowed_salary_by_variant: salario máximo permitido según la variante
-- ============================================================

PROMPT ===== 3. PREVALIDACIÓN =====

-- ESCRIBA AQUÍ SU CONSULTA O SUS CONSULTAS DE PREVALIDACIÓN

-- A. Un resumen con estas columnas:
WITH dept_stats AS (
    SELECT department_id,
           COUNT(*)      AS dept_count,
           AVG(salary)   AS dept_avg,
           MAX(salary)   AS dept_max
    FROM   t1_employees
    WHERE  department_id IS NOT NULL
    GROUP  BY department_id
),
hist AS (
    SELECT DISTINCT employee_id
    FROM   t1_job_history
    WHERE  start_date > ADD_MONTHS(SYSDATE, -24)
),
managers AS (
    SELECT DISTINCT manager_id AS employee_id
    FROM   t1_employees
    WHERE  manager_id IS NOT NULL
),
elegibles AS (
    SELECT
        e.employee_id,
        e.salary AS salary_before,
        ROUND(ds.dept_avg, 2) AS dept_avg,
        ROUND((ds.dept_avg - e.salary) / NULLIF(ds.dept_avg,0) * 100, 2) AS pct_gap,
        -- Porcentaje de ajuste según umbrales Variante 3
        CASE
            WHEN ROUND((ds.dept_avg - e.salary) / NULLIF(ds.dept_avg,0) * 100, 2) >= 12 THEN 7
            WHEN ROUND((ds.dept_avg - e.salary) / NULLIF(ds.dept_avg,0) * 100, 2) >=  6 THEN 4
            ELSE 2
        END AS adjustment_pct
    FROM   t1_employees   e
           JOIN dept_stats ds ON e.department_id = ds.department_id
    WHERE  e.department_id IS NOT NULL
      AND  ds.dept_count   >= 3
      AND  ROUND((SYSDATE - e.hire_date) / 365, 1) >= 4
      AND  e.employee_id NOT IN (SELECT employee_id FROM hist)
      AND  e.employee_id NOT IN (SELECT employee_id FROM managers)
)
SELECT
    COUNT(*) AS total_eligible_employees,
    ROUND(SUM(salary_before), 2) AS total_salary_before,
    ROUND(SUM(salary_before * (1 + adjustment_pct / 100)), 2) AS total_salary_after,
    ROUND(SUM(salary_before * (1 + adjustment_pct / 100))
          - SUM(salary_before), 2) AS total_increment
FROM elegibles;
--
-- B. Un detalle de empleados elegibles con estas columnas:


WITH dept_stats AS (
    SELECT department_id,
           COUNT(*)      AS dept_count,
           AVG(salary)   AS dept_avg,
           MAX(salary)   AS dept_max
    FROM   t1_employees
    WHERE  department_id IS NOT NULL
    GROUP  BY department_id
),
hist AS (
    SELECT DISTINCT employee_id
    FROM   t1_job_history
    WHERE  start_date > ADD_MONTHS(SYSDATE, -24)
),
managers AS (
    SELECT DISTINCT manager_id AS employee_id
    FROM   t1_employees
    WHERE  manager_id IS NOT NULL
),
elegibles AS (
    SELECT
        e.employee_id,
        e.department_id,
        e.salary                                                          AS salary_before,
        ROUND((ds.dept_avg - e.salary) / NULLIF(ds.dept_avg,0) * 100, 2) AS pct_gap,
        CASE
            WHEN ROUND((ds.dept_avg - e.salary) / NULLIF(ds.dept_avg,0) * 100, 2) >= 12 THEN 7
            WHEN ROUND((ds.dept_avg - e.salary) / NULLIF(ds.dept_avg,0) * 100, 2) >=  6 THEN 4
            ELSE 2
        END AS adjustment_pct,
        CASE
            WHEN ROUND((ds.dept_avg - e.salary) / NULLIF(ds.dept_avg,0) * 100, 2) >= 12 THEN 'AJUSTE_ALTO'
            WHEN ROUND((ds.dept_avg - e.salary) / NULLIF(ds.dept_avg,0) * 100, 2) >=  6 THEN 'AJUSTE_MEDIO'
            ELSE 'AJUSTE_BAJO'
        END AS rule_applied
    FROM   t1_employees   e
           JOIN dept_stats ds ON e.department_id = ds.department_id
    WHERE  e.department_id IS NOT NULL
      AND  ds.dept_count   >= 3
      AND  ROUND((SYSDATE - e.hire_date) / 365, 1) >= 4
      AND  e.employee_id NOT IN (SELECT employee_id FROM hist)
      AND  e.employee_id NOT IN (SELECT employee_id FROM managers)
)
SELECT
    employee_id,
    department_id,
    salary_before,
    ROUND(salary_before * (1 + adjustment_pct / 100), 2) AS salary_after,
    adjustment_pct,
    rule_applied
FROM elegibles
ORDER BY department_id, salary_before DESC;

--
-- C. Un control de topes por departamento con estas columnas:
WITH dept_stats AS (
    SELECT
        e.department_id,
        d.department_name,
        COUNT(*) AS dept_count,
        AVG(e.salary) AS dept_avg,
        MAX(e.salary) AS dept_max
    FROM   t1_employees   e
           JOIN t1_departments d ON e.department_id = d.department_id
    WHERE  e.department_id IS NOT NULL
    GROUP  BY e.department_id, d.department_name
)
SELECT
    ds.department_id,
    ds.department_name,
    ROUND(ds.dept_avg, 2) AS dept_avg_salary,
    ROUND(ds.dept_max, 2) AS dept_max_salary,
    -- Variante 3: máximo permitido = promedio * 118 / 100
    ROUND(ds.dept_avg * 118 / 100, 2) AS max_allowed_salary_by_variant
FROM   dept_stats ds
WHERE  ds.dept_count >= 3
ORDER BY ds.department_id;

/**
employee_id - ID único del empleado que cumple los criterios de elegibilidad

department_id - ID del departamento al que pertenece el empleado

salary_before - Salario actual del empleado (antes del ajuste)

salary_after - Salario después de aplicar el incremento porcentual correspondiente

adjustment_pct - Porcentaje de incremento aplicado (2, 4 o 7)

rule_applied - Categoría del ajuste

*//


-- ============================================================
-- 4. EJECUCIÓN TRANSACCIONAL
-- OBJETIVO:
-- Ejecutar la actualización real y registrar la auditoría.
--
-- DEBE INCLUIR OBLIGATORIAMENTE:
-- 1. SAVEPOINT
-- 2. UPDATE o MERGE para actualizar salarios
-- 3. INSERT a AUDIT_SALARY_ADJUSTMENTS_T1
-- 4. Validación intermedia
-- 5. COMMIT o ROLLBACK TO SAVEPOINT
--
-- IMPORTANTE:
-- - La auditoría debe usar el valor &p_execution_tag
-- - La auditoría debe usar el valor &p_variant_id
-- - Debe usar la secuencia AUDIT_SALARY_ADJ_T1_SEQ.NEXTVAL
-- ============================================================

PROMPT ===== 4. EJECUCIÓN TRANSACCIONAL =====

SAVEPOINT sv_before_adjustment;

-- 4.1 ACTUALIZACIÓN DE SALARIOS
-- ESCRIBA AQUÍ SU UPDATE O MERGE
-- Debe actualizar únicamente empleados ELEGIBLES.


UPDATE t1_employees e
SET e.salary = (
    WITH variante AS (SELECT *FROM t1_variants WHERE variant_id = &&p_variant_id),
    dept_stats AS (
        SELECT department_id, AVG(salary) dept_avg_salary, COUNT(*) dept_employee_count
        FROM t1_employees WHERE department_id IS NOT NULL GROUP BY department_id
    ),
    elegibles AS (
        SELECT e2.employee_id,
            LEAST(
                ROUND(e2.salary * (1 + 
                    CASE WHEN (ds.dept_avg_salary - e2.salary)/ds.dept_avg_salary*100 > v.gap_high_threshold_pct THEN v.raise_high_pct
                         WHEN (ds.dept_avg_salary - e2.salary)/ds.dept_avg_salary*100 > v.gap_mid_threshold_pct THEN v.raise_mid_pct
                         ELSE v.raise_low_pct
                    END / 100), 2),
                ROUND(ds.dept_avg_salary * v.max_salary_vs_avg_pct / 100, 2)
            ) AS new_salary
        FROM t1_employees e2, variante v, dept_stats ds
        WHERE e2.department_id = ds.department_id
          AND e2.department_id IS NOT NULL
          AND e2.department_id != v.excluded_department_id
          AND ds.dept_employee_count >= 3
          AND MONTHS_BETWEEN(SYSDATE, e2.hire_date)/12 >= v.min_years_service
          AND NOT EXISTS (SELECT 1 FROM t1_job_history jh WHERE jh.employee_id = e2.employee_id 
                          AND jh.start_date >= ADD_MONTHS(SYSDATE, -v.recent_job_history_months))
          AND NOT EXISTS (SELECT 1 FROM t1_departments d WHERE d.manager_id = e2.employee_id)
          AND ds.dept_avg_salary > e2.salary
    )
    SELECT new_salary FROM elegibles WHERE elegibles.employee_id = e.employee_id
)
WHERE EXISTS (SELECT 1 FROM t1_employees e2
              WHERE e2.employee_id = e.employee_id
                AND e2.department_id IS NOT NULL
                AND e2.department_id != (SELECT excluded_department_id FROM t1_variants 
                WHERE variant_id = &&p_variant_id)
                AND (SELECT COUNT(*) FROM t1_employees
                WHERE department_id = e2.department_id) >= 3
                AND MONTHS_BETWEEN(SYSDATE, e2.hire_date)/12 >= (SELECT min_years_service FROM t1_variants 
                WHERE variant_id = &&p_variant_id)
                AND NOT EXISTS (SELECT 1 FROM t1_job_history jh 
                WHERE jh.employee_id = e2.employee_id 
                AND jh.start_date >= ADD_MONTHS(SYSDATE, -(SELECT recent_job_history_months FROM t1_variants 
                WHERE variant_id = &&p_variant_id)))
                AND NOT EXISTS (SELECT 1 FROM t1_departments d 
                WHERE d.manager_id = e2.employee_id)
                AND (SELECT AVG(salary) FROM t1_employees WHERE department_id = e2.department_id) > e2.salary);

-- 4.2 INSERCIÓN EN AUDITORÍA
-- Debe llenar estas columnas de AUDIT_SALARY_ADJUSTMENTS_T1:
--   audit_id               -> usar AUDIT_SALARY_ADJ_T1_SEQ.NEXTVAL
--   execution_tag          -> usar &p_execution_tag
--   variant_id             -> usar &p_variant_id
--   employee_id            -> id del empleado ajustado
--   department_id          -> departamento del empleado
--   salary_before          -> salario antes del ajuste
--   salary_after           -> salario después del ajuste
--   pct_gap_to_avg_before  -> brecha porcentual antes del ajuste
--   rule_applied           -> regla aplicada
--   executed_by            -> USER
--   executed_at            -> SYSDATE
--   notes                  -> comentario libre

-- ESCRIBA AQUÍ SU SELECT O VALUES PARA INSERTAR LA AUDITORÍA

PROMPT ===== 4.2 INSERCIÓN EN AUDITORÍA =====

INSERT INTO audit_salary_adjustments_t1 (
    audit_id, execution_tag, variant_id, employee_id, department_id,
    salary_before, salary_after, pct_gap_to_avg_before, rule_applied, 
    executed_by, executed_at, notes
)
WITH variante AS (SELECT * FROM t1_variants WHERE variant_id = &&p_variant_id),
dept_stats AS (
    SELECT department_id, AVG(salary) dept_avg_salary, COUNT(*) dept_employee_count
    FROM t1_employees WHERE department_id IS NOT NULL GROUP BY department_id
)
SELECT
    audit_salary_adj_t1_seq.NEXTVAL,
    '&&p_execution_tag',
    &&p_variant_id,
    e.employee_id,
    e.department_id,
    e.salary,
    ROUND(e.salary * (1 + 
        CASE WHEN (ds.dept_avg_salary - e.salary)/ds.dept_avg_salary*100 > v.gap_high_threshold_pct THEN v.raise_high_pct
        WHEN (ds.dept_avg_salary - e.salary)/ds.dept_avg_salary*100 > v.gap_mid_threshold_pct THEN v.raise_mid_pct
        ELSE v.raise_low_pct
        END / 100), 2),
    ROUND((ds.dept_avg_salary - e.salary) / ds.dept_avg_salary * 100, 4),
    CASE WHEN (ds.dept_avg_salary - e.salary)/ds.dept_avg_salary*100 > v.gap_high_threshold_pct THEN 'AJUSTE_ALTO'
         WHEN (ds.dept_avg_salary - e.salary)/ds.dept_avg_salary*100 > v.gap_mid_threshold_pct THEN 'AJUSTE_MEDIO'
         ELSE 'AJUSTE_BAJO'
    END,
    USER,
    SYSDATE,
    'Ajuste salarial - Variante ' || &&p_variant_id
    FROM t1_employees e, variante v, dept_stats ds
    WHERE e.department_id = ds.department_id
    AND e.department_id != v.excluded_department_id
    AND ds.dept_employee_count >= 3
    AND MONTHS_BETWEEN(SYSDATE, e.hire_date)/12 >= v.min_years_service
    AND NOT EXISTS (SELECT 1 FROM t1_job_history jh WHERE jh.employee_id = e.employee_id 
                  AND jh.start_date >= ADD_MONTHS(SYSDATE, -v.recent_job_history_months))
    AND NOT EXISTS (SELECT 1 FROM t1_departments d WHERE d.manager_id = e.employee_id)
    AND ds.dept_avg_salary > e.salary;
-- 4.3 VALIDACIÓN INTERMEDIA
-- Debe mostrar, como mínimo, estas columnas:
--   employee_id
--   department_id
--   current_salary
--   original_salary
--   allowed_max_salary
--   validation_status
--
-- validation_status debe indicar si cumple o no cumple.

PROMPT ===== 4.3 VALIDACIÓN INTERMEDIA =====

WITH variante AS (SELECT * FROM t1_variants WHERE variant_id = &&p_variant_id),
dept_stats AS (
    SELECT department_id, AVG(salary) dept_avg_salary
    FROM t1_employees WHERE department_id IS NOT NULL GROUP BY department_id
),
empleados_actualizados AS (
    SELECT e.employee_id, e.department_id, e.salary AS current_salary,
           ds.dept_avg_salary * v.max_salary_vs_avg_pct / 100 AS allowed_max_salary
    FROM t1_employees e, variante v, dept_stats ds
    WHERE e.department_id = ds.department_id
      AND e.department_id != v.excluded_department_id
      AND EXISTS (SELECT 1 FROM audit_salary_adjustments_t1 a 
                  WHERE a.employee_id = e.employee_id AND a.execution_tag = '&&p_execution_tag')
)
SELECT employee_id, department_id, 
       ROUND(current_salary, 2) AS current_salary,
       ROUND(allowed_max_salary, 2) AS allowed_max_salary,
       CASE WHEN current_salary <= allowed_max_salary THEN 'CUMPLE' ELSE 'NO_CUMPLE' END AS validation_status
FROM empleados_actualizados
ORDER BY department_id, employee_id;

-- 4.4 CONTROL TRANSACCIONAL
-- Debe demostrar UNO de estos escenarios:
-- A. COMMIT si toda la validación es correcta
-- B. ROLLBACK TO SAVEPOINT si detecta incumplimientos
--
-- ESCRIBA AQUÍ SU DECISIÓN TRANSACCIONAL Y AGREGUE UN COMENTARIO

DECLARE
    v_has_violation NUMBER;
BEGIN
    WITH variante AS (SELECT * FROM t1_variants WHERE variant_id = 3),
    dept_stats AS (
        SELECT department_id, AVG(salary) dept_avg_salary
        FROM t1_employees WHERE department_id IS NOT NULL GROUP BY department_id
    )
    SELECT COUNT(*) INTO v_has_violation
    FROM t1_employees e, variante v, dept_stats ds
    WHERE e.department_id = ds.department_id
      AND e.salary > ds.dept_avg_salary * v.max_salary_vs_avg_pct / 100
      AND EXISTS (SELECT 1 FROM audit_salary_adjustments_t1 a 
                  WHERE a.employee_id = e.employee_id AND a.execution_tag = 'P03_FINAL');

    IF v_has_violation = 0 THEN
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('COMMIT realizado - Todos los salarios respetan los topes');
    ELSE
        ROLLBACK TO sv_before_adjustment;
        DBMS_OUTPUT.PUT_LINE('ROLLBACK realizado - Se detectaron ' || v_has_violation || ' empleados fuera de tope');
    END IF;
END;
/
-- explicando por qué hizo COMMIT o por qué hizo ROLLBACK.
/**
COMMIT: Se ejecuta cuando v_has_violation = 0, es decir, ningún empleado
supera el tope máximo del promedio del departamento. 
*/


-- ============================================================
-- 5. VALIDACIÓN POSTERIOR
-- OBJETIVO:
-- Demostrar el resultado final de la transacción.
--
-- DEBE MOSTRAR, COMO MÍNIMO, ESTAS 4 SALIDAS:
--
-- SALIDA 1. Empleados impactados
-- Columnas mínimas:
--   employee_id, first_name, last_name, department_id,
--   salary_before, salary_after, execution_tag
--
-- SALIDA 2. Resumen económico final
-- Columnas mínimas:
--   total_rows_audited, total_salary_before, total_salary_after, total_increment
--
-- SALIDA 3. Validación de topes
-- Columnas mínimas:
--   employee_id, department_id, salary_after, allowed_max_salary, top_limit_status
--
-- SALIDA 4. Auditoría generada
-- Columnas mínimas:
--   audit_id, execution_tag, variant_id, employee_id, department_id,
--   salary_before, salary_after, rule_applied, executed_by, executed_at
--
-- IMPORTANTE:
-- Todas las validaciones posteriores deben filtrar por &p_execution_tag
-- ============================================================

PROMPT ===== 5. VALIDACIÓN POSTERIOR =====

-- SALIDA 1. EMPLEADOS IMPACTADOS
SELECT
a.employee_id,
e.first_name,
e.last_name,
a.department_id,
a.salary_before,
a.salary_after,
a.execution_tag
FROM
audit_salary_adjustments_t1 a
JOIN t1_employees e ON a.employee_id = e.employee_id
WHERE
a.execution_tag = '&p_execution_tag'
AND a.variant_id = &p_variant_id
ORDER BY
a.department_id,
a.employee_id;


-- SALIDA 2. RESUMEN ECONÓMICO FINAL
SELECT
COUNT(*) AS total_rows_audited,
ROUND(SUM(salary_before), 2) AS total_salary_before,
ROUND(SUM(salary_after), 2) AS total_salary_after,
ROUND(SUM(salary_after) - SUM(salary_before), 2) AS total_increment
FROM
audit_salary_adjustments_t1
WHERE
execution_tag = '&p_execution_tag'
AND variant_id = &p_variant_id;


-- SALIDA 3. VALIDACIÓN DE TOPES

WITH variante AS (
SELECT * FROM t1_variants WHERE variant_id = &p_variant_id
),
dept_stats AS (
SELECT
department_id,
AVG(salary) AS dept_avg_salary
FROM
t1_employees
WHERE
department_id IS NOT NULL
GROUP BY
department_id
)
SELECT
a.employee_id,
a.department_id,
a.salary_after,
ROUND(ds.dept_avg_salary * v.max_salary_vs_avg_pct / 100, 2) AS allowed_max_salary,
CASE
WHEN a.salary_after <= ROUND(ds.dept_avg_salary * v.max_salary_vs_avg_pct / 100, 2)
THEN 'CUMPLE_TOPE'
ELSE 'SUPERA_TOPE'
END AS top_limit_status
FROM
audit_salary_adjustments_t1 a
CROSS JOIN variante v
JOIN dept_stats ds ON a.department_id = ds.department_id
WHERE
a.execution_tag = '&p_execution_tag'
AND a.variant_id = &p_variant_id
ORDER BY
a.department_id,
a.employee_id;


-- SALIDA 4. AUDITORÍA GENERADA

SELECT
audit_id,
execution_tag,
variant_id,
employee_id,
department_id,
salary_before,
salary_after,
rule_applied,
executed_by,
TO_CHAR(executed_at, 'YYYY-MM-DD HH24:MI:SS') AS executed_at,
notes
FROM
audit_salary_adjustments_t1
WHERE
execution_tag = '&p_execution_tag'
AND variant_id = &p_variant_id
ORDER BY
audit_id;


-- ============================================================
-- 6. JUSTIFICACIÓN TÉCNICA
-- ============================================================

-- ATOMICIDAD:
-- Todo el proceso de actualización de salarios y registro de auditoría se ejecuta dentro de una misma transacción. Se crea un 
-- SAVEPOINT antes de iniciar los cambios y, si la validación intermedia detecta inconsistencias, se ejecuta ROLLBACK TO SAVEPOINT 

-- CONSISTENCIA:
-- Las reglas de elegibilidad se aplican según los parámetrosde la variante 3 obtenidos desde T1_VARIANTS. La validación
-- posterior verifica que ningún salario supere el tope máximo Si alguna fila incumple,
-- se revierte la transacción manteniendo la integridad.

-- AISLAMIENTO:
-- El bloqueo a nivel de fila para las filas actualizadas. Otras sesiones no verán los cambios hasta ejecutar COMMIT,
-- evitando lecturas sucias. Si múltiples sesiones intentan actualizar los mismos empleados, el motor serializa las
-- operaciones automáticamente.

-- DURABILIDAD:
-- Una vez ejecutado COMMIT, los cambios se escriben en losredo logs y datafiles. En caso de fallo del sistema, 
-- este recupera automáticamente todas las transacciones confirmadas durante el proceso de recovery, garantizando persistencia.

-- USO DE SAVEPOINT / ROLLBACK: 
-- El SAVEPOINT sv_before_adjustment se crea estratégicamente ANTES del UPDATE para controlar el riesgo de que algún salario supere 
-- el tope máximo tras el ajuste. Este punto de restauración es necesario porque permite deshacer 
-- selectiva toda la transacción sin afectar operaciones previas al script

PROMPT ===== Fin de plantilla =====



