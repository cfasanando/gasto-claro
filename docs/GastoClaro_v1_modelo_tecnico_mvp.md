# GastoClaro v1 - Modelo técnico del MVP

## 1. Propósito del documento

Este documento redefine el MVP de **GastoClaro** con enfoque personal y operativo.

La app ya no se plantea primero como un simple registro genérico de gastos, sino como una herramienta para:

- controlar flujo de caja mensual
- visualizar vencimientos cercanos
- registrar deudas y cuotas
- proyectar si el mes alcanza o no
- confirmar pagos realizados
- ordenar ingresos programados

El primer usuario del producto será su propio creador, por lo que el diseño del MVP prioriza utilidad real antes que generalización.

---

## 2. Enfoque funcional del MVP

### Preguntas que el MVP debe responder

1. ¿Qué tengo que pagar esta semana y este mes?
2. ¿Cuánto necesito para cubrir mis pagos obligatorios?
3. ¿Qué deudas tienen mayor presión mensual?
4. ¿Qué ingresos entrarán este mes y en qué fecha o periodo?
5. ¿Cuál es mi saldo proyectado después de cubrir lo obligatorio?
6. ¿Qué pagos ya hice, cuáles siguen pendientes y cuáles están vencidos?

### Objetivo del MVP

Construir una primera versión móvil y web que permita:

- registrar ingresos programados
- registrar gastos fijos
- registrar deudas y obligaciones
- ver vencimientos
- calcular presión mensual
- marcar pagos realizados
- ver un dashboard mensual simple

---

## 3. Módulos definitivos del MVP

### Módulo 1: Dashboard mensual
Debe mostrar:

- ingreso esperado del mes
- total de pagos obligatorios del mes
- saldo proyectado
- pagos vencidos
- pagos próximos
- resumen por tipo de obligación

### Módulo 2: Vencimientos
Debe mostrar:

- pagos de los próximos 7 días
- pagos de los próximos 30 días
- pagos vencidos
- pagos ya realizados
- filtro por tipo de obligación

### Módulo 3: Deudas y obligaciones
Debe permitir registrar y visualizar:

- tarjetas de crédito
- préstamos bancarios
- préstamos a terceros
- pagos fijos a tiendas
- juntas o compromisos mensuales

### Módulo 4: Ingresos programados
Debe permitir registrar:

- sueldo
- vacaciones
- gratificaciones
- CTS
- ingresos extra
- ingresos futuros de nuevos proyectos

### Módulo 5: Gastos fijos
Debe permitir registrar gastos recurrentes del hogar y personales:

- alquiler
- servicios
- comida
- estudios
- salud
- transporte
- membresías
- otros fijos

### Módulo 6: Registro de pagos
Debe permitir:

- marcar pago como realizado
- marcar pago parcial
- marcar pago pendiente
- registrar fecha real de pago
- registrar monto real pagado
- registrar observaciones

---

## 4. Pantallas del MVP

### Pantallas principales

1. Dashboard mensual
2. Vencimientos
3. Deudas y obligaciones
4. Ingresos programados
5. Gastos fijos
6. Registro de pagos
7. Detalle de obligación
8. Resumen mensual
9. Configuración básica

### Navegación sugerida

Tabs principales:

- Inicio
- Vencimientos
- Deudas
- Ingresos
- Más

Botón rápido:

- Registrar pago

---

## 5. Modelo de datos del MVP

## 5.1 Tabla: users

### Objetivo
Guardar el usuario propietario de la información.

### Campos
- id
- name
- email
- password
- preferred_currency
- timezone
- is_active
- created_at
- updated_at

---

## 5.2 Tabla: income_sources

### Objetivo
Definir fuentes de ingreso recurrentes o conocidas.

### Ejemplos
- Beeznest
- Eco Agua
- Ingreso extra
- Gratificación
- CTS
- Vacaciones

### Campos
- id
- user_id
- name
- type
- default_amount
- currency
- is_active
- notes
- created_at
- updated_at

### Valores sugeridos para `type`
- salary
- bonus
- cts
- vacation
- freelance
- business
- other

---

## 5.3 Tabla: income_events

### Objetivo
Registrar ingresos esperados o recibidos por mes o fecha.

### Campos
- id
- user_id
- income_source_id
- title
- amount
- currency
- expected_date
- received_date
- status
- notes
- created_at
- updated_at

### Valores sugeridos para `status`
- planned
- received
- missed

---

## 5.4 Tabla: fixed_expenses

### Objetivo
Guardar gastos mensuales recurrentes.

### Ejemplos
- alquiler
- luz
- agua
- celular
- internet
- comida
- estudios
- gym
- junta
- Ripley

### Campos
- id
- user_id
- name
- category
- amount
- currency
- due_day
- frequency
- is_mandatory
- is_active
- notes
- created_at
- updated_at

### Valores sugeridos para `frequency`
- monthly
- weekly
- yearly

---

## 5.5 Tabla: debts

### Objetivo
Representar toda obligación financiera que tenga saldo, cuota o vencimiento.

### Tipos de deuda sugeridos
- credit_card
- bank_loan
- third_party_loan
- store_credit
- recurring_commitment

### Campos
- id
- user_id
- debt_type
- name
- creditor_name
- currency
- original_amount
- current_balance
- monthly_due_amount
- minimum_payment
- interest_rate_monthly
- due_day
- status
- has_fixed_payment
- notes
- created_at
- updated_at

### Valores sugeridos para `status`
- active
- paid
- suspended
- cancelled

### Notas de modelado
Para simplificar el MVP, cuando una misma deuda tenga parte en soles y parte en dólares, conviene crear registros separados.

Ejemplo:
- Visa Oro Interbank PEN
- Visa Oro Interbank USD

---

## 5.6 Tabla: payment_obligations

### Objetivo
Generar o registrar obligaciones concretas de pago por mes.

Esta tabla puede agrupar obligaciones provenientes de:
- deudas
- gastos fijos
- pagos manuales
- compromisos especiales

### Campos
- id
- user_id
- source_type
- source_id
- title
- obligation_type
- amount_due
- currency
- due_date
- status
- priority
- notes
- created_at
- updated_at

### Valores sugeridos para `source_type`
- fixed_expense
- debt
- manual

### Valores sugeridos para `obligation_type`
- fixed_expense
- minimum_payment
- monthly_installment
- interest_payment
- manual_commitment

### Valores sugeridos para `status`
- pending
- partial
- paid
- overdue
- cancelled

---

## 5.7 Tabla: payment_records

### Objetivo
Guardar pagos reales ejecutados por el usuario.

### Campos
- id
- user_id
- payment_obligation_id
- paid_amount
- currency
- paid_at
- payment_method
- note
- created_at
- updated_at

### Valores sugeridos para `payment_method`
- cash
- bank_transfer
- credit_card
- debit_card
- yape
- plin
- other

---

## 5.8 Tabla: monthly_snapshots

### Objetivo
Guardar resumen consolidado del mes para visualización rápida.

### Campos
- id
- user_id
- year
- month
- expected_income_total
- received_income_total
- fixed_expense_total
- debt_due_total
- obligation_total
- paid_total
- projected_balance
- created_at
- updated_at

---

## 6. Relaciones principales

- un usuario tiene muchas fuentes de ingreso
- un usuario tiene muchos eventos de ingreso
- un usuario tiene muchos gastos fijos
- un usuario tiene muchas deudas
- un usuario tiene muchas obligaciones de pago
- un usuario tiene muchos registros de pago
- una fuente de ingreso tiene muchos eventos de ingreso
- una deuda puede generar muchas obligaciones de pago
- un gasto fijo puede generar muchas obligaciones de pago
- una obligación de pago puede tener uno o varios pagos reales

---

## 7. Reglas funcionales del MVP

### Usuarios
- cada usuario solo ve su propia información
- la moneda por defecto puede ser PEN, pero cada deuda o ingreso puede tener su propia moneda

### Ingresos
- un ingreso programado puede estar planeado o recibido
- un ingreso recibido debe guardar monto y fecha real

### Gastos fijos
- deben tener monto y frecuencia
- pueden marcarse como obligatorios o no obligatorios

### Deudas
- deben tener tipo, saldo y estado
- pueden tener cuota mensual fija o solo pago mínimo
- pueden tener interés mensual

### Obligaciones de pago
- deben tener monto, fecha y estado
- el estado cambia según pagos reales registrados

### Pagos reales
- un pago parcial no cierra la obligación
- una obligación pasa a pagada cuando el total pagado cubre el monto exigido

---

## 8. Orden recomendado de implementación

## Fase 1: base funcional mínima
### Backend
- users
- debts
- fixed_expenses
- income_sources
- income_events

### Frontend
- dashboard básico
- listado de deudas
- listado de gastos fijos
- listado de ingresos programados

## Fase 2: obligaciones y vencimientos
### Backend
- payment_obligations
- lógica de vencimientos
- estados de obligaciones

### Frontend
- vista de vencimientos
- detalle de obligación
- filtros por estado

## Fase 3: pagos reales
### Backend
- payment_records
- recálculo de estado de obligaciones
- resumen mensual

### Frontend
- formulario de registrar pago
- pantalla de historial de pagos
- actualización del dashboard

## Fase 4: pulido del MVP
### Backend
- validaciones
- seeders iniciales
- snapshots mensuales

### Frontend
- UX del dashboard
- alertas visuales
- prioridades y colores
- ajustes básicos

---

## 9. API inicial sugerida

### Ingresos
- GET /api/income-sources
- POST /api/income-sources
- GET /api/income-events
- POST /api/income-events
- PUT /api/income-events/{id}

### Gastos fijos
- GET /api/fixed-expenses
- POST /api/fixed-expenses
- PUT /api/fixed-expenses/{id}

### Deudas
- GET /api/debts
- POST /api/debts
- GET /api/debts/{id}
- PUT /api/debts/{id}

### Obligaciones
- GET /api/payment-obligations
- POST /api/payment-obligations
- PUT /api/payment-obligations/{id}

### Pagos
- GET /api/payment-records
- POST /api/payment-records

### Dashboard
- GET /api/dashboard/monthly
- GET /api/dashboard/upcoming
- GET /api/dashboard/overdue

---

## 10. Seed inicial sugerido para el primer uso personal

### Gastos fijos iniciales
- Alquiler
- Luz
- Agua
- Celular
- Internet
- Comida
- Suplementos
- Medicina
- Gasolina
- Gym
- Zegel Contabilidad
- UTP
- Junta mensual
- Ripley

### Deudas iniciales
- Visa Oro Interbank PEN
- Visa Oro Interbank USD
- Visa Oro BCP PEN
- Visa Oro BCP USD
- IBK Visa Access
- Crédito efectivo BCP
- Crédito Niko Scotiabank
- Sra Casanova
- Jeampierr
- Raul
- Rosa
- Juanita
- Doctora

### Fuentes de ingreso iniciales
- Beeznest sueldo
- Beeznest vacaciones
- Beeznest gratificación
- Beeznest CTS
- Eco Agua
- Ingreso extra

---

## 11. Criterio de éxito del MVP

El MVP será exitoso si permite que el usuario:

1. vea sus vencimientos del mes en segundos
2. sepa cuánto necesita para cubrir lo obligatorio
3. entienda si el mes está en déficit o no
4. pueda registrar pagos reales fácilmente desde el celular
5. use la app todos los días o varias veces por semana

---

## 12. Decisión de producto

La versión 1 de GastoClaro no se enfoca primero en ser una app genérica para cualquier persona.

Se enfoca en ser una herramienta personal real para:

- controlar presión financiera mensual
- ordenar deudas
- visualizar vencimientos
- proyectar liquidez
- confirmar pagos

Cuando esta versión funcione bien para su usuario principal, se podrá generalizar para otros perfiles.
