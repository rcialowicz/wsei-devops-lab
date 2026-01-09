using Serilog;
using Serilog.Events;
using Serilog.Formatting.Json;

// Konfiguracja Serilog
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
    .Enrich.FromLogContext()
    .Enrich.WithProperty("Application", "MonitoringDemo")
    .Enrich.WithProperty("Environment", "Production")
    .WriteTo.Console(new JsonFormatter())
    .CreateLogger();

try
{
    Log.Information("Starting MonitoringDemo API");

    var builder = WebApplication.CreateBuilder(args);

    // Użyj Serilog jako providera logowania
    builder.Host.UseSerilog();

    // Application Insights
    builder.Services.AddApplicationInsightsTelemetry();

    // Dodaj TelemetryClient jako Singleton
    builder.Services.AddSingleton<Microsoft.ApplicationInsights.TelemetryClient>();

    builder.Services.AddEndpointsApiExplorer();
    builder.Services.AddSwaggerGen();

    var app = builder.Build();

    // Włącz Swagger w każdym środowisku (łatwiejsze testowanie)
    app.UseSwagger();
    app.UseSwaggerUI();

    // Middleware do logowania requestów
    app.Use(async (context, next) =>
    {
        var logger = context.RequestServices.GetRequiredService<ILogger<Program>>();
        
        logger.LogInformation("Incoming request: {Method} {Path} from {IP}", 
            context.Request.Method, 
            context.Request.Path, 
            context.Connection.RemoteIpAddress);

        await next();
    });

    // Przekieruj główną stronę na Swagger
    app.MapGet("/", () => Results.Redirect("/swagger"))
        .ExcludeFromDescription();

    // Endpoint 1: Health check
    app.MapGet("/health", () =>
    {
        Log.Information("Health check called");
        return Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow });
    })
    .WithName("HealthCheck")
    .WithOpenApi();

    // Endpoint 2: Get products (sukces)
    app.MapGet("/api/products", (ILogger<Program> logger) =>
    {
        logger.LogInformation("Fetching products list");
        
        var products = new[]
        {
            new { id = 1, name = "Laptop", price = 2999.99, category = "Electronics" },
            new { id = 2, name = "Mouse", price = 49.99, category = "Electronics" },
            new { id = 3, name = "Keyboard", price = 149.99, category = "Electronics" }
        };

        logger.LogInformation("Returned {ProductCount} products", products.Length);
        return Results.Ok(products);
    })
    .WithName("GetProducts")
    .WithOpenApi();

    // Endpoint 3: Get product by ID (może zwrócić 404)
    app.MapGet("/api/products/{id}", (int id, ILogger<Program> logger) =>
    {
        logger.LogInformation("Fetching product with ID: {ProductId}", id);

        if (id <= 0 || id > 3)
        {
            logger.LogWarning("Product not found: {ProductId}", id);
            return Results.NotFound(new { error = "Product not found", productId = id });
        }

        var product = new { id, name = $"Product {id}", price = 99.99 * id };
        logger.LogInformation("Product found: {@Product}", product);
        return Results.Ok(product);
    })
    .WithName("GetProductById")
    .WithOpenApi();

    // Endpoint 4: Create order (symuluje błąd dla określonych przypadków)
    app.MapPost("/api/orders", (
        OrderRequest order, 
        ILogger<Program> logger,
        Microsoft.ApplicationInsights.TelemetryClient telemetry) =>
    {
        logger.LogInformation("Creating order: {@Order}", order);

        // Symulacja walidacji
        if (order.ProductId <= 0)
        {
            logger.LogError("Invalid order: ProductId must be positive. Received: {ProductId}", order.ProductId);
            return Results.BadRequest(new { error = "Invalid ProductId" });
        }

        if (order.Quantity <= 0)
        {
            logger.LogError("Invalid order: Quantity must be positive. Received: {Quantity}", order.Quantity);
            return Results.BadRequest(new { error = "Invalid Quantity" });
        }

        // Symulacja błędu dla quantity > 100 (out of stock)
        if (order.Quantity > 100)
        {
            logger.LogWarning("Order failed: Out of stock. ProductId: {ProductId}, Quantity: {Quantity}", 
                order.ProductId, order.Quantity);

            // Track custom event: OrderFailed
            telemetry.TrackEvent("OrderFailed", 
                properties: new Dictionary<string, string>
                {
                    { "Reason", "OutOfStock" },
                    { "ProductId", order.ProductId.ToString() },
                    { "RequestedQuantity", order.Quantity.ToString() }
                });

            return Results.Problem(
                detail: "Requested quantity exceeds available stock",
                statusCode: 409,
                title: "Out of Stock"
            );
        }

        var orderId = Guid.NewGuid();
        var revenue = order.Quantity * 99.99; // Przykładowa cena

        logger.LogInformation("Order created successfully: {OrderId}, ProductId: {ProductId}, Quantity: {Quantity}", 
            orderId, order.ProductId, order.Quantity);

        // Track custom event: OrderCreated
        telemetry.TrackEvent("OrderCreated",
            properties: new Dictionary<string, string>
            {
                { "OrderId", orderId.ToString() },
                { "ProductId", order.ProductId.ToString() },
                { "Quantity", order.Quantity.ToString() },
                { "CustomerEmail", order.CustomerEmail ?? "anonymous" }
            },
            metrics: new Dictionary<string, double>
            {
                { "Revenue", revenue },
                { "Quantity", order.Quantity }
            });

        // Track custom metric: Revenue
        telemetry.TrackMetric("OrderRevenue", revenue);

        return Results.Created($"/api/orders/{orderId}", new
        {
            orderId,
            productId = order.ProductId,
            quantity = order.Quantity,
            revenue,
            status = "confirmed",
            createdAt = DateTime.UtcNow
        });
    })
    .WithName("CreateOrder")
    .WithOpenApi();

    // Endpoint 5: Symulacja błędu (do testowania)
    app.MapGet("/api/crash", (ILogger<Program> logger) =>
    {
        logger.LogError("Crash endpoint called - simulating exception");
        throw new InvalidOperationException("This is a simulated crash for testing!");
    })
    .WithName("SimulateCrash")
    .WithOpenApi();

    // Endpoint 6: Wolny endpoint (symulacja wysokiej latencji)
    app.MapGet("/api/slow", async (ILogger<Program> logger) =>
    {
        logger.LogWarning("Slow endpoint called - simulating delay");
        await Task.Delay(TimeSpan.FromSeconds(3));
        logger.LogInformation("Slow endpoint completed");
        return Results.Ok(new { message = "This took 3 seconds" });
    })
    .WithName("SlowEndpoint")
    .WithOpenApi();

    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Application terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}

// Record dla Order Request
record OrderRequest(int ProductId, int Quantity, string? CustomerEmail);
