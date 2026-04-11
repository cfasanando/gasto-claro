# GastoClaro v1 — Enfoque personal de flujo, deudas y vencimientos

## 1. Replanteamiento del producto

GastoClaro ya no se plantea primero como una app genérica de finanzas personales.

La versión 1 debe enfocarse en resolver un problema real y cotidiano del usuario fundador:

- controlar gastos fijos mensuales
- registrar ingresos esperados por mes
- visualizar vencimientos cercanos
- administrar deudas con bancos, tarjetas y terceros
- proyectar si el dinero del mes alcanza o no
- priorizar qué pagar primero

### Nueva definición del producto

**GastoClaro v1** es una app personal para controlar:

- flujo mensual de caja
- deudas activas
- pagos obligatorios
- fechas de vencimiento
- ingresos programados
- déficit o superávit proyectado

## 2. Usuario inicial

El primer usuario del sistema será el propio creador de la app.

Eso cambia la estrategia del MVP:

- primero se construye algo realmente útil para uso diario
- luego se generaliza para más personas
- las decisiones funcionales se basan en problemas reales, no solo en ideas genéricas de finanzas

## 3. Problema principal que debe resolver

El problema no es solo registrar gastos.

El problema real es:

- hay gastos fijos mensuales
- hay ingresos que cambian según el mes
- hay deudas con distintas fechas y distintos tipos
- hay obligaciones en soles y dólares
- hay préstamos a terceros con intereses mensuales
- hace falta saber qué vence primero, qué presiona más y si el mes alcanzará

## 4. Objetivos funcionales del MVP

La app debe responder estas preguntas:

1. ¿Qué pagos vencen esta semana y este mes?
2. ¿Cuánto dinero necesito para cubrir todo lo obligatorio?
3. ¿Cuánto me faltará o me sobrará este mes?
4. ¿Qué deuda está presionando más mi flujo mensual?
5. ¿Qué meses del año son más favorables por vacaciones, CTS o gratificación?
6. ¿Qué pagos ya hice, cuáles siguen pendientes y cuáles vencieron?

## 5. Principios del producto

- mobile first
- simple de usar en el día a día
- orientada a flujo real, no a contabilidad compleja
- primero utilidad personal, luego generalización
- pocas pantallas, mucha claridad
- priorizar vencimientos, pagos y proyección mensual

## 6. Nuevo MVP priorizado

### Módulo 1. Dashboard mensual
Es la pantalla principal.

Debe mostrar:

- mes seleccionado
- ingresos esperados del mes
- pagos obligatorios del mes
- saldo proyectado
- total pagado
- total pendiente
- alerta si el saldo proyectado es negativo
- próximos vencimientos

### Módulo 2. Vencimientos
Debe mostrar:

- pagos de los próximos 7 días
- pagos de los próximos 30 días
- pagos vencidos
- fecha de pago
- tipo de obligación
- monto
- estado

### Módulo 3. Deudas
Debe permitir administrar tres grandes tipos:

- tarjetas de crédito
- préstamos bancarios
- préstamos a terceros

Cada deuda debe guardar al menos:

- nombre
- acreedor
- tipo
- moneda
- saldo actual
- pago mensual o pago mínimo
- día de vencimiento
- interés mensual si aplica
- notas
- activa o inactiva

### Módulo 4. Ingresos programados
Debe permitir registrar ingresos del año o del mes.

Ejemplos:

- sueldo
- vacaciones
- CTS
- gratificación
- ingreso extraordinario
- ingreso de Eco Agua

Cada ingreso debe tener:

- fuente
- tipo
- fecha esperada
- monto esperado
- monto real opcional
- estado

### Módulo 5. Gastos fijos
Debe permitir registrar pagos fijos mensuales.

Ejemplos:

- alquiler
- luz
- agua
- celular
- internet
- comida
- suplementos
- medicina
- gasolina
- gimnasio
- estudios
- junta mensual
- cuota Ripley

Cada gasto fijo debe tener:

- nombre
- categoría
- monto
- frecuencia
- día de pago
- obligatorio o no
- activo o inactivo

### Módulo 6. Registro de pagos reales
Debe permitir confirmar ejecución real de pagos.

Acciones:

- marcar como pagado
- registrar pago parcial
- dejar como pendiente
- dejar como vencido

Campos:

- fecha real de pago
- monto pagado
- observación

### Módulo 7. Escenarios de pago
No tiene que ser complejo al inicio.

Debe permitir algo como:

- si este mes tengo solo X, ¿qué cubro primero?
- si entra gratificación, ¿a qué deuda conviene aplicarla?
- si priorizo una deuda privada con alto interés, ¿cómo baja la presión del mes siguiente?

## 7. Módulos que bajan de prioridad

Estos módulos no son prioridad para la versión 1:

- red social
- comunidad
- gráficos avanzados
- metas de ahorro decorativas
- exportación PDF
- integración bancaria
- multiusuario
- marketplace
- IA

## 8. Pantallas sugeridas del MVP

### Públicas
- Splash
- Login
- Registro

### Privadas
- Dashboard mensual
- Vencimientos
- Deudas
- Detalle de deuda
- Gastos fijos
- Ingresos programados
- Registro de pago
- Configuración

## 9. Modelo de datos propuesto

## 9.1 users

```sql
id
name
email
password
preferred_currency
timezone
is_active
created_at
updated_at
```

## 9.2 debt_types
Tabla catálogo.

```sql
id
code
name
created_at
updated_at
```

Valores sugeridos:

- credit_card
- bank_loan
- third_party_loan
- store_credit
- recurring_commitment

## 9.3 debts
Tabla principal de deudas y obligaciones financieras.

```sql
id
user_id
debt_type_id
name
creditor_name
currency
current_balance
monthly_due_amount
minimum_payment
interest_rate_monthly
due_day
start_date
end_date
notes
is_active
created_at
updated_at
```

### Observaciones
- `currency` puede ser `PEN` o `USD`
- para tarjetas con saldos en dos monedas, conviene manejar registros separados por moneda en el MVP
- `monthly_due_amount` sirve para cuota o pago esperado
- `minimum_payment` sirve especialmente para tarjetas

## 9.4 fixed_expenses
Tabla para gastos fijos mensuales no necesariamente financieros.

```sql
id
user_id
name
category
amount
currency
frequency
due_day
is_required
is_active
notes
created_at
updated_at
```

Valores sugeridos:

- frequency: monthly
- category: housing, utilities, food, health, study, transport, gym, other

## 9.5 income_sources
Fuentes de ingreso.

```sql
id
user_id
name
type
is_active
notes
created_at
updated_at
```

Ejemplos:

- BeezNest salario
- BeezNest vacaciones
- BeezNest gratificación
- BeezNest CTS
- Eco Agua
- Freelance

## 9.6 income_events
Ingresos esperados o reales por fecha.

```sql
id
user_id
income_source_id
name
expected_date
expected_amount
actual_amount
currency
status
notes
created_at
updated_at
```

Valores sugeridos para `status`:

- planned
- received
- cancelled

## 9.7 payment_obligations
Tabla unificada para construir el calendario mensual.
Puede generarse automáticamente o mantenerse como tabla explícita en una segunda etapa.

Versión simple para iniciar:

```sql
id
user_id
source_type
source_id
name
amount
currency
due_date
status
priority
notes
created_at
updated_at
```

Valores sugeridos para `source_type`:

- debt
- fixed_expense
- custom

Valores sugeridos para `status`:

- pending
- paid
- partial
- overdue

## 9.8 payment_records
Pagos reales registrados por el usuario.

```sql
id
user_id
payment_obligation_id
paid_amount
currency
paid_at
payment_method
notes
created_at
updated_at
```

## 9.9 monthly_snapshots
Resumen mensual consolidado.

```sql
id
user_id
year
month
expected_income
expected_expenses
expected_debt_payments
total_paid
pending_amount
projected_balance
created_at
updated_at
```

## 10. Relaciones principales

- un usuario tiene muchas deudas
- un usuario tiene muchos gastos fijos
- un usuario tiene muchas fuentes de ingreso
- un usuario tiene muchos eventos de ingreso
- un usuario tiene muchas obligaciones de pago
- una obligación de pago puede generar uno o más registros de pago

## 11. Enfoque técnico recomendado para v1

### Backend
Laravel API

### App
Flutter

### Base de datos
PostgreSQL

### Prioridad de desarrollo
1. Dashboard mensual
2. Deudas
3. Gastos fijos
4. Ingresos programados
5. Vencimientos
6. Registro de pagos
7. Login y pulido final

## 12. Roadmap corto

### Etapa 1
- redefinir producto
- definir entidades
- crear backend base
- crear app base
- probar conexión Flutter ↔ Laravel

### Etapa 2
- CRUD de deudas
- CRUD de gastos fijos
- CRUD de ingresos programados

### Etapa 3
- cálculo del dashboard mensual
- calendario de vencimientos
- registro de pagos reales

### Etapa 4
- validaciones
- ajustes visuales
- prueba diaria en celular

## 13. Criterio de éxito del MVP

La versión 1 será exitosa si permite al usuario abrir la app en su celular y responder en menos de un minuto:

- cuánto ingresa este mes
- cuánto debe pagar este mes
- qué vence primero
- cuánto ya pagó
- cuánto le falta
- si terminará el mes en déficit o no

## 14. Notas de producto

- el producto puede seguir llamándose GastoClaro
- el posicionamiento interno debe ser: control personal de flujo y deudas
- primero debe servirle al fundador
- luego se podrá generalizar para otros usuarios

