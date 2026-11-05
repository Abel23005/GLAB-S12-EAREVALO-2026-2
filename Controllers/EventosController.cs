using EventosApi.Data;
using EventosApi.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace EventosApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class EventosController(EventosContext db) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Evento>>> Get([FromQuery] int? categoriaId, [FromQuery] DateTime? desde, [FromQuery] DateTime? hasta)
    {
        var consulta = db.Eventos.AsNoTracking().Include(e => e.Categoria).AsQueryable();
        if (categoriaId.HasValue) consulta = consulta.Where(e => e.CategoriaId == categoriaId.Value);
        if (desde.HasValue) consulta = consulta.Where(e => e.Fecha >= desde.Value);
        if (hasta.HasValue) consulta = consulta.Where(e => e.Fecha <= hasta.Value);
        return await consulta.OrderBy(e => e.Fecha).ToListAsync();
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<Evento>> Get(int id)
    {
        var evento = await db.Eventos.AsNoTracking().Include(e => e.Categoria).FirstOrDefaultAsync(e => e.Id == id);
        return evento is null ? NotFound() : Ok(evento);
    }

    [HttpPost]
    public async Task<ActionResult<Evento>> Post(Evento evento)
    {
        if (!await db.Categorias.AnyAsync(c => c.Id == evento.CategoriaId))
            return BadRequest(new { mensaje = "La categoría indicada no existe." });
        if (await db.Eventos.AnyAsync(e => e.Titulo == evento.Titulo && e.Fecha == evento.Fecha))
            return Conflict(new { mensaje = "Ya existe un evento con ese título y fecha." });
        evento.Categoria = null;
        db.Eventos.Add(evento);
        await db.SaveChangesAsync();
        return CreatedAtAction(nameof(Get), new { id = evento.Id }, evento);
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Put(int id, Evento evento)
    {
        if (id != evento.Id) return BadRequest(new { mensaje = "El id de la ruta debe coincidir con el cuerpo." });
        var actual = await db.Eventos.FindAsync(id);
        if (actual is null) return NotFound();
        if (!await db.Categorias.AnyAsync(c => c.Id == evento.CategoriaId))
            return BadRequest(new { mensaje = "La categoría indicada no existe." });
        if (await db.Eventos.AnyAsync(e => e.Id != id && e.Titulo == evento.Titulo && e.Fecha == evento.Fecha))
            return Conflict(new { mensaje = "Ya existe un evento con ese título y fecha." });
        actual.Titulo = evento.Titulo;
        actual.Lugar = evento.Lugar;
        actual.Fecha = evento.Fecha;
        actual.Aforo = evento.Aforo;
        actual.Precio = evento.Precio;
        actual.CategoriaId = evento.CategoriaId;
        await db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var evento = await db.Eventos.FindAsync(id);
        if (evento is null) return NotFound();
        db.Eventos.Remove(evento);
        await db.SaveChangesAsync();
        return NoContent();
    }
}
