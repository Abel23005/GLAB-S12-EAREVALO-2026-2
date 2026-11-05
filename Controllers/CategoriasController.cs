using EventosApi.Data;
using EventosApi.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace EventosApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CategoriasController(EventosContext db) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Categoria>>> Get() =>
        await db.Categorias.AsNoTracking().OrderBy(c => c.Nombre).ToListAsync();

    [HttpGet("{id:int}")]
    public async Task<ActionResult<Categoria>> Get(int id)
    {
        var categoria = await db.Categorias.AsNoTracking().FirstOrDefaultAsync(c => c.Id == id);
        return categoria is null ? NotFound() : Ok(categoria);
    }

    [HttpGet("{id:int}/eventos")]
    public async Task<ActionResult<IEnumerable<Evento>>> GetEventos(int id)
    {
        if (!await db.Categorias.AnyAsync(c => c.Id == id)) return NotFound();
        return await db.Eventos.AsNoTracking().Where(e => e.CategoriaId == id).OrderBy(e => e.Fecha).ToListAsync();
    }

    [HttpPost]
    public async Task<ActionResult<Categoria>> Post(Categoria categoria)
    {
        if (await db.Categorias.AnyAsync(c => c.Nombre == categoria.Nombre))
            return Conflict(new { mensaje = "Ya existe una categoría con ese nombre." });
        db.Categorias.Add(categoria);
        await db.SaveChangesAsync();
        return CreatedAtAction(nameof(Get), new { id = categoria.Id }, categoria);
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Put(int id, Categoria categoria)
    {
        if (id != categoria.Id) return BadRequest(new { mensaje = "El id de la ruta debe coincidir con el cuerpo." });
        var actual = await db.Categorias.FindAsync(id);
        if (actual is null) return NotFound();
        if (await db.Categorias.AnyAsync(c => c.Id != id && c.Nombre == categoria.Nombre))
            return Conflict(new { mensaje = "Ya existe una categoría con ese nombre." });
        actual.Nombre = categoria.Nombre;
        actual.Descripcion = categoria.Descripcion;
        await db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var categoria = await db.Categorias.FindAsync(id);
        if (categoria is null) return NotFound();
        if (await db.Eventos.AnyAsync(e => e.CategoriaId == id))
            return Conflict(new { mensaje = "No se puede eliminar una categoría que tiene eventos." });
        db.Categorias.Remove(categoria);
        await db.SaveChangesAsync();
        return NoContent();
    }
}
