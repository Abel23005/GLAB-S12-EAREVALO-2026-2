# EventosApi - GLAB S12

API REST para administrar eventos culturales. El sistema organiza eventos por categoría y aplica validaciones para evitar categorías duplicadas, eventos repetidos y la eliminación de categorías que todavía tienen eventos.

## Modelo y base de datos

`Categoria` tiene muchos `Evento` (relación 1:N). La base PostgreSQL contiene las tablas `Categorias` y `Eventos`, claves foráneas, restricciones e índices únicos. EF Core usa el proveedor `Npgsql.EntityFrameworkCore.PostgreSQL`. Se eligió PostgreSQL para poder usar Neon en su nivel gratuito; el hosting de la API será Render. Al migrar desde SQL Server se sustituyeron `IDENTITY` por columnas identity de PostgreSQL, `nvarchar` por `varchar`, `datetime2` por `timestamp with time zone` y la sintaxis de fechas y lotes `GO` por SQL compatible con PostgreSQL. Las reglas, entidades y respuestas HTTP se conservan. Las entidades usan Data Annotations y `[JsonIgnore]` para evitar ciclos; `Evento.Categoria` admite nulo para que el POST pueda enviar solo `CategoriaId`.

El script `sql/01_EventosApiDB.sql` crea las tablas, restricciones, índices y datos de ejemplo dentro de la base Neon ya creada. Ejecútalo una sola vez en el editor SQL de Neon. No incluye secretos ni cadena de conexión.

## Ejecutar localmente

Requisitos: .NET 10 SDK y una base PostgreSQL (Neon para el despliegue).

```powershell
$env:ConnectionStrings__EventosDB = "Host=TU_HOST;Database=neondb;Username=TU_USUARIO;Password=TU_PASSWORD;SSL Mode=Require;Trust Server Certificate=true"
dotnet run
```

Swagger UI: `/swagger`. En Neon, copia los parámetros de conexión desde el panel del proyecto y mantenlos fuera del repositorio. En Render se configura la variable de entorno `ConnectionStrings__EventosDB` como secreto.

## Endpoints

La interfaz de gestión también está incluida en el proyecto y se sirve desde /. Permite buscar y filtrar eventos, administrar eventos y categorías con formularios, y ver el resumen de la agenda. Swagger sigue disponible en /swagger.

- Categorías: `GET /api/categorias`, `GET /api/categorias/{id}`, `GET /api/categorias/{id}/eventos`, `POST /api/categorias`, `PUT /api/categorias/{id}`, `DELETE /api/categorias/{id}`.
- Eventos: `GET /api/eventos?categoriaId=1&desde=2026-11-01&hasta=2026-12-31`, `GET /api/eventos/{id}`, `POST /api/eventos`, `PUT /api/eventos/{id}`, `DELETE /api/eventos/{id}`.

Hay 11 acciones. Todas son asíncronas y consultan con LINQ/EF Core. Los controladores usan directamente el DbContext. CORS permite un origen concreto, configurable con `Cors__AllowedOrigin` (por defecto `http://localhost:5173`).

## Reglas y respuestas

- 409 si se repite el nombre de una categoría, el título y fecha de un evento, o se intenta borrar una categoría con eventos.
- 400 si el id de ruta difiere del cuerpo, la categoría referenciada no existe o los datos no pasan la validación automática.
- 201 para altas, 200 para consultas, 204 para actualizaciones y eliminaciones correctas y 404 si el recurso no existe.

## Despliegue en la nube

La solución seleccionada es Neon PostgreSQL para datos y Render Web Service con Docker para la API. Neon ofrece en el plan Free una cuota de almacenamiento y cómputo mensual sin tarjeta, adecuada para prototipos; la base puede escalar a cero cuando queda inactiva ([planes Neon](https://neon.com/docs/introduction/plans)). Render entrega una URL pública, pero sus servicios web gratuitos se duermen tras periodos sin tráfico; la primera petición posterior puede tardar en reactivarlos ([Render: límites del plan gratuito](https://render.com/docs/free)).

El `Dockerfile` prepara la API para Render. El código está en [GitHub](https://github.com/Abel23005/GLAB-S12-EAREVALO-2026-2). Render usa `ConnectionStrings__EventosDB` como secreto y Neon con SSL. El script PostgreSQL de este repositorio crea el esquema y los datos de ejemplo en Neon. `ASPNETCORE_FORWARDEDHEADERS_ENABLED=true` permite que ASP.NET Core respete HTTPS terminado en el proxy de Render y construya correctamente las cabeceras `Location` de las altas.

- API: <https://eventos-api-glab-s12.onrender.com>
- Swagger: <https://eventos-api-glab-s12.onrender.com/swagger/index.html>
- Render: servicio `eventos-api-glab-s12`, plan Free, conectado a `main`.
- Verificación en nube: 28 casos cubren las 11 acciones y las respuestas 200, 201, 204, 400, 404 y 409; 28 correctos, 0 fallidos. El script reproducible es `Evidencias/verificar-api-cloud.ps1`; los resultados están en `Evidencias/resultados-cloud.csv` y `Evidencias/resultados-cloud.md`.
