using System;
using System.Collections.Generic;
using EventosApi.Models;
using Microsoft.EntityFrameworkCore;

namespace EventosApi.Data;

public partial class EventosContext : DbContext
{
    public EventosContext(DbContextOptions<EventosContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Categoria> Categorias { get; set; }

    public virtual DbSet<Evento> Eventos { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Categoria>(entity =>
        {
            entity.HasIndex(e => e.Nombre, "UQ_Categorias_Nombre").IsUnique();

            entity.Property(e => e.Descripcion).HasMaxLength(250);
            entity.Property(e => e.Nombre).HasMaxLength(60);
        });

        modelBuilder.Entity<Evento>(entity =>
        {
            entity.HasIndex(e => new { e.Titulo, e.Fecha }, "UX_Eventos_Titulo_Fecha").IsUnique();

            entity.Property(e => e.Lugar).HasMaxLength(150);
            entity.Property(e => e.Precio).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.Titulo).HasMaxLength(120);

            entity.HasOne(d => d.Categoria).WithMany(p => p.Eventos)
                .HasForeignKey(d => d.CategoriaId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Eventos_Categorias");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
