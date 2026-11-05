using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace EventosApi.Models;

public partial class Categoria
{
    public int Id { get; set; }

    [Required, StringLength(60, MinimumLength = 2)]
    public string Nombre { get; set; } = null!;

    [StringLength(250)]
    public string? Descripcion { get; set; }

    [JsonIgnore]
    public virtual ICollection<Evento> Eventos { get; set; } = new List<Evento>();
}
