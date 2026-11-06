using EventosApi.Data;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddDbContext<EventosContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("EventosDB")));
builder.Services.AddCors(options => options.AddPolicy("ClienteWeb", policy =>
    policy.WithOrigins(builder.Configuration["Cors:AllowedOrigin"] ?? "http://localhost:5173")
          .AllowAnyHeader().AllowAnyMethod()));

var app = builder.Build();
app.UseSwagger();
app.UseSwaggerUI();
app.UseDefaultFiles();
app.UseStaticFiles();
// Render terminates HTTPS at its load balancer and forwards HTTP to this container.
app.UseCors("ClienteWeb");
app.MapControllers();
app.Run();

