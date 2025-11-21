using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Add CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// Add SQL Server database
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Initialize database on startup
using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    // Simple approach: ensure database and tables exist
    dbContext.Database.EnsureCreated();
}

app.UseCors("AllowAll");

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// GET endpoint - Get all products
app.MapGet("/api/products", async (AppDbContext db) =>
{
    var products = await db.Products.OrderByDescending(p => p.Id).ToListAsync();
    return Results.Ok(products);
})
.WithName("GetProducts");

// POST endpoint - Add new product
app.MapPost("/api/products", async (Product product, AppDbContext db) =>
{
    if (string.IsNullOrWhiteSpace(product.Name))
    {
        return Results.BadRequest(new { error = "Product name is required" });
    }

    product.CreatedAt = DateTime.UtcNow;
    db.Products.Add(product);
    await db.SaveChangesAsync();
    
    return Results.Created($"/api/products/{product.Id}", product);
})
.WithName("AddProduct");

// Health check endpoint
app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }))
.WithName("HealthCheck");

app.Run();

// Database Context
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }
    
    public DbSet<Product> Products { get; set; }
}

// Product Model
public class Product
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}
