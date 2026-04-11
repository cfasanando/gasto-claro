# GastoClaro v1 - Roadmap técnico de implementación

## 1. Objetivo del roadmap

Este roadmap organiza la construcción de **GastoClaro v1** como una herramienta personal real de:

- control de flujo mensual
- seguimiento de vencimientos
- control de deudas
- registro de ingresos programados
- confirmación de pagos realizados

La prioridad no es construir una app genérica desde el día uno, sino una app útil para su primer usuario real.

---

## 2. Principios de implementación

1. Construir primero lo que da valor inmediato en el celular.
2. Evitar módulos genéricos que no ayuden al problema principal.
3. Mantener backend y frontend simples al inicio.
4. Trabajar de forma incremental y visible.
5. No optimizar antes de tener una primera versión útil.
6. Mantener la arquitectura preparada para crecer, pero sin sobreingeniería.

---

## 3. Entregables por fase

## Fase 0 - Base ya lograda
### Estado actual
- entorno local funcional
- Laravel creado y corriendo
- Flutter creado y corriendo
- conexión Flutter -> Laravel validada con `/api/ping`
- documentación base del enfoque y modelo técnico creada

### Resultado
Ya existe una base técnica real para seguir construyendo.

---

## Fase 1 - Fundaciones del dominio
### Objetivo
Definir y construir las entidades principales del MVP.

### Backend
Crear migraciones, modelos, controladores y rutas para:

- debts
- fixed_expenses
- income_sources
- income_events

### Frontend
Crear estructura base de carpetas y pantallas vacías para:

- dashboard
- debts
- fixed_expenses
- income_events

### Entregables
- API CRUD mínima de deudas
- API CRUD mínima de gastos fijos
- API CRUD mínima de fuentes de ingreso
- API CRUD mínima de ingresos programados
- pantallas base navegables en Flutter

### Resultado esperado
Ya se puede registrar la información estructural principal del sistema.

---

## Fase 2 - Dashboard mensual simple
### Objetivo
Mostrar una vista mensual útil desde el celular.

### Backend
Crear endpoint tipo:

- GET `/api/dashboard/monthly`

Este endpoint debe devolver:
- ingreso esperado del mes
- ingreso recibido del mes
- gastos fijos activos del mes
- deuda exigible del mes
- saldo proyectado
- pagos próximos
- pagos vencidos

### Frontend
Construir pantalla de Dashboard con:
- tarjetas de resumen
- próximos vencimientos
- alertas de déficit
- lista corta de pagos urgentes

### Entregables
- primer dashboard funcional
- información mensual consolidada
- uso real como pantalla principal

### Resultado esperado
El usuario puede abrir la app y entender rápidamente su situación del mes.

---

## Fase 3 - Obligaciones de pago y vencimientos
### Objetivo
Pasar de datos sueltos a compromisos mensuales concretos.

### Backend
Crear:

- payment_obligations
- lógica para listar vencimientos
- estados: pending, partial, paid, overdue

Endpoints sugeridos:
- GET `/api/payment-obligations`
- POST `/api/payment-obligations`
- PUT `/api/payment-obligations/{id}`
- GET `/api/dashboard/upcoming`
- GET `/api/dashboard/overdue`

### Frontend
Construir:
- pantalla de vencimientos
- filtros por estado
- filtros por tipo
- detalle de obligación

### Entregables
- vista de pagos próximos
- vista de pagos vencidos
- primera vista operativa del calendario financiero

### Resultado esperado
La app ya sirve para saber qué pagar primero.

---

## Fase 4 - Registro real de pagos
### Objetivo
Permitir que la app refleje la realidad y no solo la proyección.

### Backend
Crear:

- payment_records
- lógica de recálculo de estado de obligación
- suma de pagos parciales

Endpoints sugeridos:
- GET `/api/payment-records`
- POST `/api/payment-records`

### Frontend
Construir:
- formulario de registrar pago
- opción de pago parcial
- historial de pagos
- refresco del dashboard tras registrar pago

### Entregables
- flujo completo de marcar pago
- actualización automática de obligación
- historial básico

### Resultado esperado
La app ya acompaña el día a día real y no solo el plan.

---

## Fase 5 - UX útil para uso diario
### Objetivo
Pulir la experiencia móvil para uso constante.

### Backend
- seeders iniciales
- validaciones más claras
- respuestas API consistentes
- valores por defecto para primer uso

### Frontend
- colores por prioridad
- indicadores visuales de vencido / urgente / pagado
- acciones rápidas
- mejor diseño del dashboard
- navegación estable

### Entregables
- app más clara y usable
- menos fricción para registrar pagos o revisar el mes
- flujo diario más natural

### Resultado esperado
La app se vuelve realmente cómoda para uso constante en el celular.

---

## Fase 6 - Resumen mensual y proyección
### Objetivo
Dar lectura financiera más completa del mes.

### Backend
Crear:
- monthly_snapshots
- cálculo de presión mensual
- comparación entre ingreso esperado y obligaciones

Endpoints sugeridos:
- GET `/api/dashboard/monthly`
- GET `/api/dashboard/summary`
- GET `/api/dashboard/projection`

### Frontend
Construir:
- resumen del mes
- proyección de cierre
- indicador de superávit o déficit
- top obligaciones del mes

### Entregables
- balance proyectado
- vista mensual consolidada
- mejor soporte para decisión de pagos

### Resultado esperado
El usuario entiende no solo qué debe pagar, sino si realmente podrá cubrirlo.

---

## 4. Orden recomendado de backend

## Sprint Backend 1
- instalar Sanctum si no está listo para uso real
- crear tablas:
  - debts
  - fixed_expenses
  - income_sources
  - income_events
- crear modelos Eloquent
- crear rutas API base
- validar CRUD mínimo

## Sprint Backend 2
- crear endpoint de dashboard mensual
- crear lógica de agregación mensual
- definir formato JSON del dashboard

## Sprint Backend 3
- crear payment_obligations
- crear filtros de pendientes, vencidos, próximos

## Sprint Backend 4
- crear payment_records
- recalcular estado de obligaciones
- actualizar dashboard con pagos reales

## Sprint Backend 5
- crear monthly_snapshots
- optimizar consultas
- agregar seeders personales iniciales

---

## 5. Orden recomendado de frontend

## Sprint Frontend 1
- limpiar proyecto Flutter base
- definir estructura de carpetas
- definir navegación principal
- crear pantallas vacías

## Sprint Frontend 2
- pantalla de deudas
- pantalla de gastos fijos
- pantalla de ingresos programados
- consumo de APIs básicas

## Sprint Frontend 3
- pantalla dashboard
- tarjetas de resumen
- vencimientos próximos

## Sprint Frontend 4
- pantalla de obligaciones
- detalle de obligación
- filtros de estado

## Sprint Frontend 5
- formulario registrar pago
- historial de pagos
- refresco de datos

## Sprint Frontend 6
- pulido visual
- prioridades y colores
- mensajes de error
- estados vacíos
- carga y retry

---

## 6. Roadmap sugerido por semanas

## Semana 1
- cerrar documentación del MVP
- crear tablas y modelos base
- CRUD de deudas
- CRUD de gastos fijos
- CRUD de ingresos programados

## Semana 2
- construir pantallas base Flutter
- conectar listados con backend
- cargar datos reales iniciales

## Semana 3
- crear dashboard mensual
- crear primeras tarjetas de resumen
- validar flujo útil del mes

## Semana 4
- crear obligaciones y vencimientos
- crear estados pending / overdue / paid

## Semana 5
- registrar pagos reales
- reflejar pagos parciales
- actualizar dashboard

## Semana 6
- pulido de UX
- carga de tus datos reales completos
- pruebas móviles diarias
- ajustes de negocio

---

## 7. Prioridades absolutas

Lo que sí va primero:
- dashboard mensual
- vencimientos
- deudas
- ingresos programados
- registrar pagos

Lo que no va primero:
- social
- multiusuario
- exportación PDF
- IA
- conexión bancaria
- sincronización compleja
- notificaciones avanzadas
- app pública para todos

---

## 8. Seed de primer uso personal

Conviene crear un seeder inicial con tus datos reales base.

### Gastos fijos
- Alquiler
- Luz
- Agua
- Celular
- Internet
- Comida
- Suplementos
- Medicina
- Gasolina
- Membresía Gym
- Zegel Contabilidad
- UTP
- Junta mensual
- Ripley mensual

### Deudas
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

### Ingresos
- Beeznest sueldo
- Beeznest vacaciones
- Beeznest gratificación
- Beeznest CTS
- Eco Agua

---

## 9. Definición de "hecho"

Un módulo se considera terminado cuando cumple esto:

### Backend
- migraciones listas
- modelos listos
- rutas API funcionando
- validaciones básicas
- respuestas JSON consistentes

### Frontend
- pantalla usable
- carga datos reales
- muestra errores correctamente
- permite acción principal sin fricción

### Producto
- aporta utilidad directa al usuario real
- puede probarse en celular sin explicación adicional

---

## 10. Próximo orden real recomendado

### Paso inmediato 1
Ajustar y confirmar el modelo oficial de tablas.

### Paso inmediato 2
Construir primero backend de:
- debts
- fixed_expenses
- income_sources
- income_events

### Paso inmediato 3
Crear en Flutter la navegación mínima y los listados base.

### Paso inmediato 4
Construir dashboard mensual.

---

## 11. Commit titles sugeridos

- Define technical roadmap for GastoClaro v1
- Add initial financial domain model
- Create base debt management module
- Add fixed expenses module
- Add income planning module
- Build monthly dashboard endpoint
- Connect Flutter lists to financial API
- Add payment obligations workflow
- Add payment records and status recalculation

---

## 12. Conclusión

La construcción correcta de GastoClaro v1 debe seguir esta lógica:

1. modelar bien
2. cargar datos reales
3. mostrar el mes
4. mostrar vencimientos
5. permitir registrar pagos
6. recién luego generalizar

La app debe convertirse primero en una herramienta diaria real para su primer usuario.
