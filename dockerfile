FROM alpine:3 AS base

FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
COPY ./vdb_node_api /vdb_node_api
COPY ./vdb_node_wireguard_manipulator /vdb_node_wireguard_manipulator
RUN dotnet publish /vdb_node_api/vdb_node_api.csproj -c "Release" -r linux-musl-x64 --no-self-contained -o /app/publish

FROM base AS final
COPY ./build_alpine/pre-wg0.conf ./etc/wireguard/wg0.conf
COPY --from=build /app/publish /app
RUN apk add -q --no-progress wireguard-tools
RUN apk add -q --no-progress aspnetcore7-runtime
RUN wg genkey >> /etc/wireguard/wg0.conf
ENV ASPNETCORE_ENVIRONMENT=Production

CMD wg-quick up wg0 && dotnet /app/vdb_node_api.dll -no-launch-profile