CREATE DATABASE EventosApiDB;
GO
USE EventosApiDB;
GO

CREATE TABLE dbo.Categorias (
    Id int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Categorias PRIMARY KEY,
    Nombre nvarchar(60) NOT NULL,
    Descripcion nvarchar(250) NULL,
    CONSTRAINT UQ_Categorias_Nombre UNIQUE (Nombre)
);
GO
CREATE TABLE dbo.Eventos (
    Id int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Eventos PRIMARY KEY,
    Titulo nvarchar(120) NOT NULL,
    Lugar nvarchar(150) NOT NULL,
    Fecha datetime2 NOT NULL,
    Aforo int NOT NULL,
    Precio decimal(18,2) NOT NULL,
    CategoriaId int NOT NULL,
    CONSTRAINT FK_Eventos_Categorias FOREIGN KEY (CategoriaId) REFERENCES dbo.Categorias(Id),
    CONSTRAINT CK_Eventos_Aforo CHECK (Aforo BETWEEN 1 AND 50000),
    CONSTRAINT CK_Eventos_Precio CHECK (Precio >= 0)
);
GO
CREATE UNIQUE INDEX UX_Eventos_Titulo_Fecha ON dbo.Eventos(Titulo, Fecha);
GO
INSERT INTO dbo.Categorias (Nombre, Descripcion) VALUES
(N'Música', N'Conciertos y actividades musicales'),
(N'Tecnología', N'Encuentros de innovación y tecnología'),
(N'Cultura', N'Actividades culturales y comunitarias');
GO
INSERT INTO dbo.Eventos (Titulo, Lugar, Fecha, Aforo, Precio, CategoriaId) VALUES
(N'Noche de jazz', N'Teatro Municipal', DATEADD(hour, 19, CONVERT(datetime2, DATEADD(day, 14, CONVERT(date, GETDATE())))), 180, 35.00, 1),
(N'Innovación digital', N'Centro de Convenciones', DATEADD(hour, 18, CONVERT(datetime2, DATEADD(day, 21, CONVERT(date, GETDATE())))), 300, 25.00, 2),
(N'Cine al aire libre', N'Parque Central', DATEADD(hour, 20, CONVERT(datetime2, DATEADD(day, 28, CONVERT(date, GETDATE())))), 250, 15.00, 3),
(N'Concierto acústico', N'Auditorio Norte', DATEADD(hour, 18, CONVERT(datetime2, DATEADD(day, 35, CONVERT(date, GETDATE())))), 120, 40.00, 1);
GO
