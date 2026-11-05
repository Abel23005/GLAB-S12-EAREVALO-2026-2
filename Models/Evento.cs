using System.ComponentModel.DataAnnotations;

namespace EventosApi.Models;

public partial class Evento
{
    public int Id { get; set; }

    [Required, StringLength(120, MinimumLength = 3)]
    public string Titulo { get; set; } = null!;

    [Required, StringLength(150)]
    public string Lugar { get; set; } = null!;

    [Required]
    public DateTime Fecha { get; set; }

    [Range(1, 50000)]
    public int Aforo { get; set; }

    [Range(typeof(decimal), "0", "1000000")]
    public decimal Precio { get; set; }

    [Range(1, int.MaxValue)]
    public int CategoriaId { get; set; }

    public virtual Categoria? Categoria { get; set; }
}
