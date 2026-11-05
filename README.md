# EventosApi - GLAB S12

API REST para administrar eventos culturales. El sistema organiza eventos por categoría y aplica validaciones para evitar categorías duplicadas, eventos repetidos y la eliminación de categorías que todavía tienen eventos.

## Modelo y base de datos

`Categoria` tiene muchos `Evento` (relación 1:N). La base contiene las tablas `Categorias` y `Eventos`, claves foráneas, restricciones e índices únicos. El modelo de EF Core fue generado desde SQL Server LocalDB con Scaffold (database-first). Después se añadieron Data Annotations para las validaciones y `[JsonIgnore]` a la colección para evitar ciclos; `Evento.Categoria` admite nulo para que el POST pueda enviar solo `CategoriaId`.

El script `sql/01_EventosApiDB.sql` crea la base y carga categorías y eventos de ejemplo. Se ejecuta desde SQL Server Management Studio o sqlcmd. En el entorno local utilizado para Scaffold se creó `EventosApiDB` en `(localdb)\\MSSQLLocalDB`.

## Ejecutar localmente

Requisitos: .NET 10 SDK y SQL Server.

```powershell
$env:ConnectionStrings__EventosDB = "Server=(localdb)\\MSSQLLocalDB;Database=EventosApiDB;Trusted_Connection=True;TrustServerCertificate=True"
dotnet run
```

Swagger UI: `/swagger`. Para volver a generar el modelo desde otra base, establecer `ConnectionStrings__EventosDB` y ejecutar:

```powershell
dotnet ef dbcontext scaffold "$env:ConnectionStrings__EventosDB" Microsoft.EntityFrameworkCore.SqlServer --context EventosContext --context-dir Data --output-dir Models --no-onconfiguring --force
```

Tras regenerar, conservar las Data Annotations y `[JsonIgnore]` de las entidades.

## Endpoints

La interfaz de gestión también está incluida en el proyecto y se sirve desde /. Permite buscar y filtrar eventos, administrar eventos y categorías con formularios, y ver el resumen de la agenda. Swagger sigue disponible en /swagger.

- Categorías: `GET /api/categorias`, `GET /api/categorias/{id}`, `GET /api/categorias/{id}/eventos`, `POST /api/categorias`, `PUT /api/categorias/{id}`, `DELETE /api/categorias/{id}`.
- Eventos: `GET /api/eventos?categoriaId=1&desde=2026-11-01&hasta=2026-12-31`, `GET /api/eventos/{id}`, `POST /api/eventos`, `PUT /api/eventos/{id}`, `DELETE /api/eventos/{id}`.

Hay 11 acciones. Todas son asíncronas y consultan con LINQ/EF Core. Los controladores usan directamente el DbContext. CORS permite un origen concreto, configurable con `Cors__AllowedOrigin` (por defecto `http://localhost:5173`).

## Reglas y respuestas

- 409 si se repite el nombre de una categoría, el título y fecha de un evento, o se intenta borrar una categoría con eventos.
- 400 si el id de ruta difiere del cuerpo, la categoría referenciada no existe o los datos no pasan la validación automática.
- 201 para altas, 200 para consultas, 204 para actualizaciones y eliminaciones correctas y 404 si el recurso no existe.

## Despliegue previsto

La combinación elegida para conservar SQL Server es una Web Service Docker gratuita en Render y una base Azure SQL Database con la oferta gratuita. Render admite imágenes Docker y entrega una URL pública, pero su nivel gratuito puede reiniciar o suspender servicios y no ofrece garantías de producción ([Render: servicios gratuitos](https://render.com/docs/free), [Render: Docker](https://render.com/docs/docker)). Azure SQL Database ofrece hasta 100 000 segundos vCore y 32 GB de datos y copias por base cada mes, con auto-pausa al alcanzar el límite; la oferta no tiene SLA ([Microsoft Learn: preguntas frecuentes de Azure SQL gratis](https://learn.microsoft.com/en-us/azure/azure-sql/database/free-offer-faq?view=azuresql)).

El `Dockerfile` prepara la API para Render. El código está en [GitHub](https://github.com/Abel23005/GLAB-S12-EAREVALO-2026-2). Para desplegarla aún se debe crear la base Azure SQL y ejecutar el script allí, configurar `ConnectionStrings__EventosDB` y `Cors__AllowedOrigin` en Render, y publicar el servicio. La API todavía no tiene una URL pública; las pruebas contra el entorno desplegado y sus capturas quedan pendientes hasta completar esos pasos.
