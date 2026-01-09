FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["MonitoringDemo.csproj", "./"]
RUN dotnet restore "MonitoringDemo.csproj"
COPY . .
RUN dotnet build "MonitoringDemo.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "MonitoringDemo.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "MonitoringDemo.dll"]
